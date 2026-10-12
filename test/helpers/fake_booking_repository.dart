import 'dart:async';

import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/repositories/booking_repository.dart';

import 'fake_data_repositories.dart';

/// Behaves like `public.bookings` under RLS and the `prepare_booking` /
/// `cancel_booking` database functions: rows are per user, prices come from
/// the package, and the same date / traveller / cancellation rules apply.
class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository({String? Function()? currentUserId, DateTime? today})
      : _currentUserId = currentUserId ?? (() => 'user-1'),
        _today = today ?? serverToday();

  final String? Function() _currentUserId;
  final DateTime _today;
  final _rows = <String, ({String userId, Booking booking})>{};
  int _sequence = 0;

  AppFailure? nextCreateFailure;
  AppFailure? nextLoadFailure;
  AppFailure? nextCancelFailure;

  /// Fails every single-booking read while set (not the Trips list).
  AppFailure? getFailure;
  Completer<void>? createGate;

  /// Holds `fetchMyBookings` responses (computed for the caller at request
  /// time) until completed — a slow network.
  Completer<void>? loadGate;

  /// Stores the next booking, then fails with a network error — a response
  /// lost after the server committed the row.
  bool loseNextCreateResponse = false;
  final calls = <String>[];
  final requests = <BookingRequest>[];

  /// (owner, client_request_id) → booking id: the unique constraint.
  final _requestIds = <(String, String), String>{};

  String _user() => _currentUserId() ?? (throw const AppFailure(FailureType.sessionExpired));

  /// Seeds a booking owned by [userId] (e.g. another account's).
  Booking seed({
    required String userId,
    String? id,
    DateTime? travelDate,
    BookingStatus status = BookingStatus.confirmed,
    int travelers = 2,
  }) {
    final booking = _build(
      id: id ?? 'bk-${++_sequence}',
      travelDate: travelDate ?? _today.add(const Duration(days: 30)),
      travelers: travelers,
      status: status,
      contactName: 'Seeded Traveller',
      contactPhone: '+20 100 000 0000',
    );
    _rows[booking.id] = (userId: userId, booking: booking);
    return booking;
  }

  @override
  Future<Booking> createBooking(BookingRequest request) async {
    final user = _user();
    calls.add('create');
    requests.add(request);
    await createGate?.future;
    final failure = nextCreateFailure;
    if (failure != null) {
      nextCreateFailure = null;
      throw failure;
    }
    // What SupabaseBookingRepository does on a duplicate request id.
    final requestId = request.clientRequestId;
    final existingId = requestId == null ? null : _requestIds[(user, requestId)];
    if (existingId != null) {
      final existing = _rows[existingId]!.booking;
      if (!request.matches(existing)) throw const AppFailure(FailureType.idempotencyConflict);
      return existing;
    }
    final pkg = samplePackages[request.destinationId]?.where((p) => p.id == request.packageId).firstOrNull;
    if (pkg == null) throw const AppFailure(FailureType.packageUnavailable);
    if (request.travelers > pkg.maxTravelers) throw const AppFailure(FailureType.tooManyTravelers);
    if (request.travelDate.isBefore(_today.add(const Duration(days: 1))) ||
        request.travelDate.isAfter(_today.add(const Duration(days: 365)))) {
      throw const AppFailure(FailureType.invalidTravelDate);
    }
    final booking = _build(
      id: 'bk-${++_sequence}',
      travelDate: request.travelDate,
      travelers: request.travelers,
      unitPrice: pkg.pricePerPerson,
      packageId: pkg.id,
      packageName: pkg.nameEn,
      contactName: request.contactName.trim(),
      contactPhone: request.contactPhone.trim(),
      specialRequests: request.specialRequests,
    );
    _rows[booking.id] = (userId: user, booking: booking);
    if (requestId != null) _requestIds[(user, requestId)] = booking.id;
    if (loseNextCreateResponse) {
      loseNextCreateResponse = false;
      throw const AppFailure(FailureType.network, debugMessage: 'response lost');
    }
    return booking;
  }

  @override
  Future<List<Booking>> fetchMyBookings() async {
    final user = _user();
    calls.add('list:$user');
    final failure = nextLoadFailure;
    if (failure != null) {
      nextLoadFailure = null;
      throw failure;
    }
    final mine = [
      for (final r in _rows.values)
        if (r.userId == user) r.booking
    ]..sort((a, b) => a.travelDate.compareTo(b.travelDate));
    await loadGate?.future;
    return mine;
  }

  @override
  Future<Booking> fetchBooking(String id) async {
    final user = _user();
    calls.add('get:$id');
    final persistent = getFailure;
    if (persistent != null) throw persistent;
    final failure = nextLoadFailure;
    if (failure != null) {
      nextLoadFailure = null;
      throw failure;
    }
    final row = _rows[id];
    // Another user's booking is invisible under RLS.
    if (row == null || row.userId != user) throw const AppFailure(FailureType.notFound);
    return row.booking;
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    final user = _user();
    calls.add('cancel:$id');
    final failure = nextCancelFailure;
    if (failure != null) {
      nextCancelFailure = null;
      throw failure;
    }
    final row = _rows[id];
    if (row == null || row.userId != user || row.booking.isCancelled || !row.booking.travelDate.isAfter(_today)) {
      throw const AppFailure(FailureType.bookingNotCancellable);
    }
    final b = row.booking;
    Booking cancelled({required bool withEmbeds}) => _build(
          id: b.id,
          reference: b.reference,
          travelDate: b.travelDate,
          travelers: b.travelers,
          unitPrice: b.unitPrice,
          status: BookingStatus.cancelled,
          contactName: b.contactName,
          contactPhone: b.contactPhone,
          specialRequests: b.specialRequests,
          withEmbeds: withEmbeds,
        );
    // The stored row keeps its catalog relations; the RPC result (like the
    // real `cancel_booking`) has no embedded catalog data.
    _rows[id] = (userId: user, booking: cancelled(withEmbeds: true));
    return cancelled(withEmbeds: false);
  }

  Booking storedBooking(String id) => _rows[id]!.booking;
  int countFor(String userId) => _rows.values.where((r) => r.userId == userId).length;

  Booking _build({
    required String id,
    required DateTime travelDate,
    required int travelers,
    required String contactName,
    required String contactPhone,
    String? reference,
    double unitPrice = 420,
    String packageId = 'pkg-1',
    String packageName = 'Pyramids & Old Cairo Discovery',
    BookingStatus status = BookingStatus.confirmed,
    String? specialRequests,
    bool withEmbeds = true,
  }) =>
      Booking.fromJson({
        'id': id,
        'reference': reference ?? 'RH-${id.hashCode.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 8)}',
        'destination_id': 'id-cairo',
        'package_id': packageId,
        'travel_date': formatDateOnly(travelDate),
        'travelers': travelers,
        'unit_price': unitPrice,
        'total_price': unitPrice * travelers,
        'currency': 'USD',
        'status': status.name,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'special_requests': specialRequests,
        'created_at': '2026-10-01T10:00:00Z',
        'cancelled_at': status == BookingStatus.cancelled ? '2026-10-02T10:00:00Z' : null,
        if (withEmbeds)
          'destination': {
            'id': 'id-cairo',
            'name_en': 'Cairo',
            'name_ar': 'القاهرة',
            'country_en': 'Egypt',
            'country_ar': 'مصر',
            'cover_image': 'https://example.invalid/cairo.jpg',
          },
        if (withEmbeds) 'package': {'id': packageId, 'name_en': packageName, 'name_ar': 'باقة', 'duration_days': 4},
      });
}
