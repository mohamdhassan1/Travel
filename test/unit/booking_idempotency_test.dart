import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/core/utils/ids.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/repositories/booking_repository.dart';
import 'package:rahala/data/repositories/booking_request_id_store.dart';
import 'package:rahala/logic/auth/auth_form_cubits.dart' show SubmitStatus;
import 'package:rahala/logic/booking/booking_form_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_data_repositories.dart';
import 'booking_model_test.dart' show bookingRow;

final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  BookingRequest request({int travelers = 3, String phone = '+20 100 000 0000', String? id}) => BookingRequest(
        destinationId: 'd1',
        packageId: 'p1',
        travelDate: DateTime(2026, 11, 15),
        travelers: travelers,
        contactName: 'Sara Ali',
        contactPhone: phone,
        clientRequestId: id,
      );

  group('ids', () {
    test('generateUuidV4 produces distinct RFC 4122 v4 UUIDs', () {
      final ids = {for (var i = 0; i < 500; i++) generateUuidV4()};
      expect(ids, hasLength(500));
      expect(ids.every(_uuid.hasMatch), isTrue);
    });

    test('stableDigest is deterministic, 16 hex chars, and input-sensitive', () {
      expect(stableDigest('abc'), stableDigest('abc'));
      expect(stableDigest('abc'), matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(stableDigest('abc'), isNot(stableDigest('abd')));
      expect(stableDigest('القاهرة'), isNot(stableDigest('القاهره')));
      // Pinned so web (JS numbers) and native (64-bit ints) must agree.
      expect(stableDigest(''), '811c9dc501000193');
    });
  });

  group('BookingRequest', () {
    test('sends client_request_id only when set, never owner/price/status', () {
      expect(request().toInsertJson().containsKey('client_request_id'), isFalse);
      final body = request(id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa').toInsertJson();
      expect(body['client_request_id'], 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
      for (final forbidden in ['user_id', 'unit_price', 'total_price', 'currency', 'status', 'reference']) {
        expect(body.containsKey(forbidden), isFalse, reason: forbidden);
      }
    });

    test('fingerprint ignores the request id and whitespace, but not the booking details', () {
      expect(request().fingerprint, request(id: generateUuidV4()).fingerprint);
      expect(request(phone: ' +20 100 000 0000 ').fingerprint, request().fingerprint);
      expect(request(travelers: 4).fingerprint, isNot(request().fingerprint));
      expect(request(phone: '+20 100 000 0001').fingerprint, isNot(request().fingerprint));
      expect(request().fingerprint, isNot(contains('Sara')), reason: 'no contact details in plain text');
    });

    test('matches compares what the booking was for', () {
      final booking = Booking.fromJson(bookingRow());
      expect(request().matches(booking), isTrue);
      expect(request(travelers: 2).matches(booking), isFalse);
    });
  });

  group('BookingRequestIdStore', () {
    late SharedPreferences prefs;
    var now = DateTime.utc(2026, 10, 2, 12);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      now = DateTime.utc(2026, 10, 2, 12);
    });

    BookingRequestIdStore store() => BookingRequestIdStore(prefs, now: () => now);

    test('the same attempt gets the same id, also from a new instance (app restart)', () async {
      final first = await store().idFor('fp-1');
      expect(first, matches(_uuid));
      expect(await store().idFor('fp-1'), first);
      expect(await store().idFor('fp-2'), isNot(first));
      expect(prefs.getString(BookingRequestIdStore.storageKey), isNot(contains('Sara')));
    });

    test('release forgets the attempt; the next identical booking is new', () async {
      final s = store();
      final first = await s.idFor('fp-1');
      await s.release('fp-1');
      expect(await s.idFor('fp-1'), isNot(first));
    });

    test('entries expire after the TTL', () async {
      final first = await store().idFor('fp-1');
      now = now.add(const Duration(hours: 49));
      expect(await store().idFor('fp-1'), isNot(first));
    });

    test('unreadable storage is ignored, not fatal', () async {
      await prefs.setString(BookingRequestIdStore.storageKey, '{not json');
      expect(await store().idFor('fp-1'), matches(_uuid));
      await prefs.setString(
          BookingRequestIdStore.storageKey,
          jsonEncode({
            'fp-1': {'id': 'not-a-uuid', 'at': 'x'}
          }));
      expect(await store().idFor('fp-1'), matches(_uuid));
    });
  });

  group('SupabaseBookingRepository duplicate recovery', () {
    const requestId = '5d7e8f90-1a2b-4c3d-8e4f-5a6b7c8d9e0f';
    late List<http.Request> requests;
    late http.Response Function(http.Request) respond;
    late SupabaseClient client;
    late SupabaseBookingRepository repo;

    http.Response json(Object body, {int status = 200}) =>
        http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

    setUp(() {
      requests = [];
      client = SupabaseClient(
        'https://test-project.supabase.co',
        'sb_publishable_test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          final res = respond(r);
          return http.Response.bytes(res.bodyBytes, res.statusCode, headers: res.headers, request: r);
        }),
      );
      repo = SupabaseBookingRepository(client, currentUserId: () => 'user-1');
    });
    tearDown(() => client.dispose());

    http.Response duplicate([String constraint = SupabaseBookingRepository.idempotencyConstraint]) => json({
          'code': '23505',
          'message': 'duplicate key value violates unique constraint "$constraint"',
          'details': 'Key (user_id, client_request_id) already exists.',
        }, status: 409);

    test('a retried request id returns the existing booking instead of a second one', () async {
      respond = (r) => r.method == 'POST' ? duplicate() : json([bookingRow()]);
      final booking = await repo.createBooking(request(id: requestId));

      expect(booking.reference, 'RH-3F9A1C2B');
      expect(requests.map((r) => r.method), ['POST', 'GET']);
      expect(jsonDecode(requests.first.body)['client_request_id'], requestId);
      final lookup = requests.last.url;
      expect(lookup.path, '/rest/v1/bookings');
      expect(lookup.queryParameters['client_request_id'], 'eq.$requestId');
      expect(lookup.queryParameters['select'], contains('destination:destinations('));
    });

    test('a request id that belongs to a different booking is an idempotencyConflict', () async {
      respond = (r) => r.method == 'POST' ? duplicate() : json([bookingRow()]);
      await expectLater(
        repo.createBooking(request(id: requestId, travelers: 2)),
        throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.idempotencyConflict)),
      );
    });

    test('other unique violations are not treated as retries', () async {
      respond = (r) => duplicate('bookings_reference_key');
      await expectLater(repo.createBooking(request(id: requestId)), throwsA(isA<AppFailure>()));
      expect(requests.map((r) => r.method), ['POST'], reason: 'no lookup for an unrelated constraint');
    });
  });

  group('BookingFormCubit retries', () {
    final today = DateTime(2026, 10);
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<BookingFormCubit> reviewed(FakeBookingRepository bookings) async {
      final cubit = BookingFormCubit(
        catalog: FakeCatalogRepository(),
        bookings: bookings,
        requestIds: BookingRequestIdStore(prefs),
        destinationId: 'id-cairo',
        initialPackageId: 'pkg-1',
        today: () => today,
      );
      await cubit.load();
      cubit.setTravelDate(today.add(const Duration(days: 10)));
      cubit.setTravelers(2);
      cubit.review(contactName: 'Sara Ali', contactPhone: '+20 100 000 0000', specialRequests: '');
      return cubit;
    }

    test('a lost response, then retry, books exactly once with the same request id', () async {
      final bookings = FakeBookingRepository(today: today)..loseNextCreateResponse = true;
      final cubit = await reviewed(bookings);

      await cubit.submit();
      expect(cubit.state.submission.status, SubmitStatus.failure);
      expect(cubit.state.submission.failure?.type, FailureType.network);
      expect(bookings.countFor('user-1'), 1, reason: 'the server did store it');

      await cubit.submit();
      expect(cubit.state.submission.status, SubmitStatus.success);
      expect(bookings.countFor('user-1'), 1, reason: 'no duplicate');
      expect(bookings.requests.map((r) => r.clientRequestId).toSet(), hasLength(1));
      expect(bookings.requests.first.clientRequestId, matches(_uuid));
      expect(prefs.getString(BookingRequestIdStore.storageKey), isNull, reason: 'released after success');
    });

    test('the retry after an app restart reuses the persisted request id', () async {
      final bookings = FakeBookingRepository(today: today)..loseNextCreateResponse = true;
      final before = await reviewed(bookings);
      await before.submit();
      await before.close();

      final after = await reviewed(bookings); // new cubit + new store, same device storage
      await after.submit();
      expect(after.state.submission.status, SubmitStatus.success);
      expect(bookings.countFor('user-1'), 1);
      expect(bookings.requests[0].clientRequestId, bookings.requests[1].clientRequestId);
    });

    test('a definite rejection releases the id; a separate booking gets a new one', () async {
      final bookings = FakeBookingRepository(today: today)
        ..nextCreateFailure = const AppFailure(FailureType.packageUnavailable);
      final cubit = await reviewed(bookings);
      await cubit.submit();
      expect(prefs.getString(BookingRequestIdStore.storageKey), isNull);
      await cubit.submit();
      expect(cubit.state.submission.status, SubmitStatus.success);
      expect(bookings.requests[0].clientRequestId, isNot(bookings.requests[1].clientRequestId));

      // Booking the same trip again later is a new booking, not a replay.
      final again = await reviewed(bookings);
      await again.submit();
      expect(bookings.countFor('user-1'), 2);
    });
  });
}
