import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/booking.dart';
import 'catalog_repository.dart';
import 'supabase_error_mapper.dart';

/// The signed-in user's bookings (`public.bookings`). Throws `AppFailure`.
///
/// Ownership is enforced server-side: RLS only exposes the caller's rows,
/// `user_id` defaults to `auth.uid()` and the client never sends it.
abstract interface class BookingRepository {
  /// Creates a booking. Price, currency, reference and status come back from
  /// the database. Throws on any rejection — nothing is assumed to succeed.
  Future<Booking> createBooking(BookingRequest request);

  /// The current user's bookings, soonest travel date first.
  Future<List<Booking>> fetchMyBookings();

  /// One of the current user's bookings; `notFound` for any other id.
  Future<Booking> fetchBooking(String id);

  /// Cancels through the `cancel_booking` database function, which only
  /// allows the owner to cancel a confirmed booking before its travel date.
  Future<Booking> cancelBooking(String id);
}

class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(
    this._client, {
    required String? Function() currentUserId,
    this.timeout = const Duration(seconds: 20),
  }) : _currentUserId = currentUserId;

  final SupabaseClient _client;
  final String? Function() _currentUserId;
  final Duration timeout;

  static const _table = 'bookings';

  /// Booking columns plus the catalog data needed to display it, embedded
  /// through the foreign keys (RLS on the catalog still applies).
  static const select = '*, '
      'destination:destinations(id, name_en, name_ar, country_en, country_ar, cover_image), '
      'package:destination_packages(id, name_en, name_ar, duration_days)';

  /// The unique constraint on (user_id, client_request_id).
  static const idempotencyConstraint = 'bookings_user_client_request_key';

  @override
  Future<Booking> createBooking(BookingRequest request) => _run('create', () async {
        _requireUser();
        try {
          final row =
              await _client.from(_table).insert(request.toInsertJson()).select(select).single().timeout(timeout);
          return _parse(row);
        } on PostgrestException catch (error) {
          final requestId = request.clientRequestId;
          if (requestId == null || !isDuplicateRequest(error)) rethrow;
          // A previous attempt with this request id already succeeded (its
          // response was lost). Return that booking instead of a new one.
          return _existingFor(request, requestId);
        }
      });

  Future<Booking> _existingFor(BookingRequest request, String requestId) async {
    final row =
        await _client.from(_table).select(select).eq('client_request_id', requestId).maybeSingle().timeout(timeout);
    if (row == null) {
      throw AppFailure(FailureType.idempotencyConflict, debugMessage: 'Duplicate request $requestId not visible');
    }
    final booking = _parse(row);
    if (!request.matches(booking)) {
      throw AppFailure(FailureType.idempotencyConflict,
          debugMessage: 'Request $requestId belongs to a different booking (${booking.reference})');
    }
    AppLogger.info('Bookings: request $requestId already booked as ${booking.reference}; returning it');
    return booking;
  }

  @override
  Future<List<Booking>> fetchMyBookings() => _run('load', () async {
        _requireUser();
        // postgrest-dart's `.order()` defaults to DESCENDING; be explicit.
        final rows = await _client
            .from(_table)
            .select(select)
            .order('travel_date', ascending: true)
            .order('created_at', ascending: false)
            .timeout(timeout);
        return parseRows(rows.map(_withResolvedCover).toList(), Booking.fromJson, 'bookings');
      });

  @override
  Future<Booking> fetchBooking(String id) => _run('load one', () async {
        _requireUser();
        if (!isUuid(id)) throw AppFailure(FailureType.notFound, debugMessage: 'Malformed booking id "$id"');
        final row = await _client.from(_table).select(select).eq('id', id).maybeSingle().timeout(timeout);
        // Another user's booking is invisible under RLS, so it is "not found".
        if (row == null) throw AppFailure(FailureType.notFound, debugMessage: 'No visible booking $id');
        return _parse(row);
      });

  @override
  Future<Booking> cancelBooking(String id) => _run('cancel', () async {
        _requireUser();
        if (!isUuid(id)) throw AppFailure(FailureType.notFound, debugMessage: 'Malformed booking id "$id"');
        final result = await _client.rpc<dynamic>('cancel_booking', params: {'p_booking_id': id}).timeout(timeout);
        // The function returns the updated row (without embedded catalog data).
        if (result is! Map<String, dynamic>) throw FormatException('Unexpected cancel_booking result', result);
        return _parse(result);
      });

  Booking _parse(Map<String, dynamic> row) => Booking.fromJson(_withResolvedCover(row));

  Map<String, dynamic> _withResolvedCover(Map<String, dynamic> row) {
    final destination = row['destination'];
    if (destination is! Map<String, dynamic>) return row;
    final cover = destination['cover_image'];
    if (cover is! String || cover.isEmpty || cover.startsWith('http')) return row;
    final url = _client.storage.from(SupabaseCatalogRepository.imagesBucket).getPublicUrl(cover);
    return {
      ...row,
      'destination': {...destination, 'cover_image': url},
    };
  }

  void _requireUser() {
    if (_currentUserId() == null) {
      throw const AppFailure(FailureType.sessionExpired, debugMessage: 'No signed-in user');
    }
  }

  Future<T> _run<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stack) {
      final failure = mapBookingError(error);
      if (failure.type != FailureType.notFound) {
        AppLogger.error('Bookings: $action failed (${failure.type.name})',
            error: failure.debugMessage, stackTrace: stack);
      }
      throw failure;
    }
  }
}

/// A unique violation of the booking idempotency key (and not of any other
/// unique constraint, which would be a real error).
bool isDuplicateRequest(PostgrestException error) =>
    error.code == '23505' &&
    '${error.message} ${error.details ?? ''}'.contains(SupabaseBookingRepository.idempotencyConstraint);

/// Maps the booking rules raised by the database (`prepare_booking`,
/// `cancel_booking`) to specific failures; everything else goes through the
/// shared Supabase mapper.
AppFailure mapBookingError(Object error) {
  if (error is PostgrestException) {
    final debug = '[${error.code}] ${error.message}';
    if (error.code == 'P0001') {
      final type = switch (error.message) {
        'package_unavailable' => FailureType.packageUnavailable,
        'too_many_travelers' => FailureType.tooManyTravelers,
        'invalid_travel_date' => FailureType.invalidTravelDate,
        'booking_not_cancellable' => FailureType.bookingNotCancellable,
        'booking_rate_limited' => FailureType.bookingRateLimited,
        _ => null,
      };
      if (type != null) return AppFailure(type, debugMessage: debug);
    }
    if (error.message == 'not_authenticated') return AppFailure(FailureType.sessionExpired, debugMessage: debug);
    // CHECK constraint (e.g. phone format) or FK violation (unknown package).
    if (error.code == '23514') return AppFailure(FailureType.invalidInput, debugMessage: debug);
    if (error.code == '23503') return AppFailure(FailureType.packageUnavailable, debugMessage: debug);
  }
  return mapSupabaseError(error);
}
