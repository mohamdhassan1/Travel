import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/repositories/booking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_model_test.dart' show bookingRow;

/// Runs the real Supabase booking repository against a fake HTTP server.
void main() {
  const bookingId = '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90';

  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late SupabaseClient client;
  late String? signedInUser;
  late SupabaseBookingRepository repo;

  http.Response json(Object body, {int status = 200}) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  setUp(() {
    requests = [];
    respond = (_) => json([]);
    signedInUser = '7d1e2c3b-4a5f-4e6d-8c7b-9a0f1e2d3c4b';
    client = SupabaseClient(
      'https://test-project.supabase.co',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final r = respond(request);
        return http.Response.bytes(r.bodyBytes, r.statusCode, headers: r.headers, request: request);
      }),
    );
    repo = SupabaseBookingRepository(client, currentUserId: () => signedInUser);
  });

  tearDown(() => client.dispose());

  Matcher failure(FailureType type) => throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

  final request = BookingRequest(
    destinationId: 'd1',
    packageId: 'p1',
    travelDate: DateTime(2026, 11, 15),
    travelers: 3,
    contactName: 'Sara Ali',
    contactPhone: '+20 100 000 0000',
  );

  group('createBooking', () {
    test('POSTs only the traveller\'s choices and returns the stored row', () async {
      respond = (_) => json(bookingRow(), status: 201);
      final booking = await repo.createBooking(request);

      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/rest/v1/bookings');
      expect(r.url.queryParameters['select'], contains('destination:destinations('));
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      for (final forbidden in ['user_id', 'unit_price', 'total_price', 'currency', 'status', 'reference']) {
        expect(body.containsKey(forbidden), isFalse, reason: '$forbidden must be set by the database');
      }
      expect(body['travel_date'], '2026-11-15');

      expect(booking.reference, 'RH-3F9A1C2B', reason: 'reference comes from the database');
      expect(booking.totalPrice, 540);
    });

    test('database booking rules map to specific failures', () async {
      for (final (message, type) in [
        ('package_unavailable', FailureType.packageUnavailable),
        ('too_many_travelers', FailureType.tooManyTravelers),
        ('invalid_travel_date', FailureType.invalidTravelDate),
      ]) {
        respond = (_) => json({'code': 'P0001', 'message': message}, status: 400);
        await expectLater(repo.createBooking(request), failure(type), reason: message);
      }
    });

    test('constraint violations and RLS rejections are reported, not swallowed', () async {
      respond = (_) =>
          json({'code': '23514', 'message': 'violates check constraint "bookings_contact_phone_check"'}, status: 400);
      await expectLater(repo.createBooking(request), failure(FailureType.invalidInput));

      respond = (_) => json({'code': '42501', 'message': 'new row violates row-level security policy'}, status: 403);
      await expectLater(repo.createBooking(request), failure(FailureType.permissionDenied));

      respond = (_) => json({'code': '42501', 'message': 'not_authenticated'}, status: 403);
      await expectLater(repo.createBooking(request), failure(FailureType.sessionExpired));
    });

    test('network failures are mapped', () async {
      respond = (_) => throw http.ClientException('Failed host lookup: test-project.supabase.co');
      await expectLater(repo.createBooking(request), failure(FailureType.network));
    });

    test('a malformed success response is invalidData, not a fake success', () async {
      respond = (_) => json({...bookingRow(), 'status': 'pending'}, status: 201);
      await expectLater(repo.createBooking(request), failure(FailureType.invalidData));
    });
  });

  group('reading bookings', () {
    test('fetchMyBookings orders explicitly (postgrest defaults to descending)', () async {
      respond = (_) => json([bookingRow()]);
      final list = await repo.fetchMyBookings();
      expect(list, hasLength(1));
      final order = requests.single.url.queryParameters['order']!;
      expect(order, startsWith('travel_date.asc'));
      expect(order, contains('created_at.desc'));
      expect(requests.single.url.queryParameters.containsKey('user_id'), isFalse, reason: 'RLS scopes the rows');
    });

    test('fetchBooking: another user\'s / unknown booking is notFound; malformed id sends nothing', () async {
      respond = (_) => json([]);
      await expectLater(repo.fetchBooking(bookingId), failure(FailureType.notFound));
      expect(requests.single.url.queryParameters['id'], 'eq.$bookingId');

      requests.clear();
      await expectLater(repo.fetchBooking('not-a-uuid'), failure(FailureType.notFound));
      expect(requests, isEmpty);
    });
  });

  group('cancelBooking', () {
    test('calls the cancel_booking database function', () async {
      respond = (_) => json(bookingRow(status: 'cancelled', destination: null, package: null));
      final cancelled = await repo.cancelBooking(bookingId);

      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/rest/v1/rpc/cancel_booking');
      expect(jsonDecode(r.body), {'p_booking_id': bookingId});
      expect(cancelled.isCancelled, isTrue);
    });

    test('a refusal by the database is bookingNotCancellable', () async {
      respond = (_) => json({'code': 'P0001', 'message': 'booking_not_cancellable'}, status: 400);
      await expectLater(repo.cancelBooking(bookingId), failure(FailureType.bookingNotCancellable));
    });
  });

  test('without a session nothing is sent', () async {
    signedInUser = null;
    await expectLater(repo.createBooking(request), failure(FailureType.sessionExpired));
    await expectLater(repo.fetchMyBookings(), failure(FailureType.sessionExpired));
    await expectLater(repo.cancelBooking(bookingId), failure(FailureType.sessionExpired));
    expect(requests, isEmpty);
  });
}
