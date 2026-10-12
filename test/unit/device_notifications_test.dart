import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/notifications/local_reminder_notifier.dart';
import 'package:rahala/data/notifications/push_messaging.dart';
import 'package:rahala/data/repositories/app_preferences.dart';
import 'package:rahala/data/repositories/device_token_repository.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/notifications/device_notifications_cubit.dart';
import 'package:rahala/logic/notifications/push_token_sync.dart';
import 'package:rahala/logic/notifications/reminder_syncing_booking_repository.dart';
import 'package:rahala/logic/notifications/trip_reminder_policy.dart';
import 'package:rahala/logic/notifications/trip_reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_device_notifications.dart';
import 'booking_model_test.dart' show bookingRow;

const _uuidA = '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90';
const _uuidB = '1c7a7d2f-9b2d-4b9f-8a5f-3a2e7d8c9b01';
const _uuidC = '2d8b8e3a-ac3e-4cab-9b6a-4b3f8e9dac12';

Booking booking(String id, {String travelDate = '2026-11-15', String status = 'confirmed'}) =>
    Booking.fromJson({...bookingRow(status: status, travelDate: travelDate), 'id': id});

void main() {
  final now = DateTime(2026, 10, 3, 12);

  group('TripReminderPolicy', () {
    test('09:00 local on the day before the travel date', () {
      expect(TripReminderPolicy.reminderTime(booking(_uuidA), now), DateTime(2026, 11, 14, 9).toUtc());
      // Month boundary.
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-12-01'), now),
          DateTime(2026, 11, 30, 9).toUtc());
    });

    test('no reminder for cancelled, past, or already-passed reminder moments', () {
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, status: 'cancelled'), now), isNull);
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-09-01'), now), isNull);
      // Travel tomorrow, booked at 12:00 today: 09:00 today has passed.
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-10-04'), now), isNull);
      // Same trip booked at 08:00: reminder at 09:00 today.
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-10-04'), DateTime(2026, 10, 3, 8)),
          DateTime(2026, 10, 3, 9).toUtc());
      // Less than a minute ahead is treated as passed.
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-10-04'), DateTime(2026, 10, 3, 8, 59, 30)),
          isNull);
    });

    test('09:00 is local wall-clock time in the device\'s zone (fixed zones)', () {
      Duration plus(int h) => Duration(hours: h);
      final b = booking(_uuidA); // travel 2026-11-15 → reminder 2026-11-14 09:00 local
      final early = DateTime.utc(2026, 10);
      expect(TripReminderPolicy.reminderTime(b, early, utcOffsetAt: (_) => plus(2)), DateTime.utc(2026, 11, 14, 7));
      expect(TripReminderPolicy.reminderTime(b, early, utcOffsetAt: (_) => plus(3)), DateTime.utc(2026, 11, 14, 6));
      expect(
          TripReminderPolicy.reminderTime(b, early, utcOffsetAt: (_) => Duration.zero), DateTime.utc(2026, 11, 14, 9));
      expect(TripReminderPolicy.reminderTime(b, early, utcOffsetAt: (_) => -plus(5)), DateTime.utc(2026, 11, 14, 14));
    });

    test('uses the offset on the reminder date, not today (DST)', () {
      // Summer time (+3) from late April to late October, +2 otherwise.
      Duration egypt(DateTime wall) => Duration(
          hours: (wall.isAfter(DateTime.utc(2026, 4, 24)) && wall.isBefore(DateTime.utc(2026, 10, 30))) ? 3 : 2);
      final winterNow = DateTime.utc(2026, 3, 1, 12);
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-06-10'), winterNow, utcOffsetAt: egypt),
          DateTime.utc(2026, 6, 9, 6),
          reason: '09:00 at +3 in summer');
      final summerNow = DateTime.utc(2026, 7, 1, 12);
      expect(TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-12-10'), summerNow, utcOffsetAt: egypt),
          DateTime.utc(2026, 12, 9, 7),
          reason: '09:00 at +2 in winter');
    });

    test('date boundaries and "tomorrow after 09:00" in a +3 zone', () {
      Duration plus3(DateTime _) => const Duration(hours: 3);
      // Year boundary: travel 1 Jan → 31 Dec 09:00 local.
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2027-01-01'), DateTime.utc(2026, 12),
              utcOffsetAt: plus3),
          DateTime.utc(2026, 12, 31, 6));
      // Travel tomorrow; it is 09:30 local (06:30 UTC) today: too late.
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-10-04'), DateTime.utc(2026, 10, 3, 6, 30),
              utcOffsetAt: plus3),
          isNull);
      // 08:00 local today (05:00 UTC): reminder at 09:00 local.
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-10-04'), DateTime.utc(2026, 10, 3, 5),
              utcOffsetAt: plus3),
          DateTime.utc(2026, 10, 3, 6));
      // Late evening UTC is already the next local day in +3: still the same rule.
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-10-05'), DateTime.utc(2026, 10, 3, 22),
              utcOffsetAt: plus3),
          DateTime.utc(2026, 10, 4, 6));
      // Cancelled / past never schedule, whatever the zone.
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, status: 'cancelled'), DateTime.utc(2026, 10),
              utcOffsetAt: plus3),
          isNull);
      expect(
          TripReminderPolicy.reminderTime(booking(_uuidA, travelDate: '2026-09-01'), DateTime.utc(2026, 10),
              utcOffsetAt: plus3),
          isNull);
    });

    test('the default uses the device zone: same instant as local DateTime(…, 9)', () {
      expect(TripReminderPolicy.reminderTime(booking(_uuidA), now), DateTime(2026, 11, 14, 9).toUtc());
      expect(TripReminderPolicy.reminderTime(booking(_uuidA), now)!.isUtc, isTrue);
    });

    test('an invalid stored date never reaches the scheduler', () {
      expect(() => booking(_uuidA, travelDate: '2026-13-45T00:00'), throwsFormatException);
      expect(() => booking(_uuidA, travelDate: ''), throwsFormatException);
    });

    test('notification ids are stable, positive 31-bit and per booking', () {
      final a = TripReminderPolicy.notificationId(_uuidA);
      expect(a, TripReminderPolicy.notificationId(_uuidA));
      expect(a, inInclusiveRange(0, 0x7fffffff));
      expect(TripReminderPolicy.notificationId(_uuidB), isNot(a));
    });

    test('payload round-trips; anything else decodes to null', () {
      final p = TripReminderPayload(bookingId: _uuidA, at: DateTime(2026, 11, 14, 9), languageCode: 'ar');
      expect(TripReminderPayload.decode(p.encode()), p);
      for (final bad in [
        null,
        '',
        'junk',
        '{}',
        '[]',
        jsonEncode({'kind': 'other', 'booking_id': _uuidA})
      ]) {
        expect(TripReminderPayload.decode(bad), isNull, reason: '$bad');
      }
    });
  });

  group('TripReminderScheduler', () {
    late FakeLocalReminderNotifier notifier;
    late bool enabled;
    late Locale locale;
    late TripReminderScheduler scheduler;

    setUp(() async {
      notifier = FakeLocalReminderNotifier();
      await notifier.initialize();
      enabled = true;
      locale = const Locale('en');
      scheduler = TripReminderScheduler(notifier, enabled: () => enabled, locale: () => locale, now: () => now);
      await scheduler.activate('user-1');
    });

    int idOf(String bookingId) => TripReminderPolicy.notificationId(bookingId);

    test('schedules only upcoming confirmed bookings, with real booking data', () async {
      await scheduler.syncAll('user-1', [
        booking(_uuidA),
        booking(_uuidB, status: 'cancelled'),
        booking(_uuidC, travelDate: '2026-09-01'),
      ]);
      expect(notifier.scheduled.keys, [idOf(_uuidA)]);
      final r = notifier.scheduled[idOf(_uuidA)]!;
      expect(r.at, DateTime(2026, 11, 14, 9).toUtc());
      expect(r.title, 'Your trip to Cairo is tomorrow');
      expect(r.body, contains('Weekend'));
      expect(r.body, contains('RH-3F9A1C2B'));
      expect(TripReminderPayload.decode(r.payload)?.bookingId, _uuidA);
    });

    test('repeated syncs never duplicate or needlessly reschedule', () async {
      for (var i = 0; i < 3; i++) {
        await scheduler.syncAll('user-1', [booking(_uuidA)]);
        await scheduler.bookingChanged('user-1', booking(_uuidA));
      }
      expect(notifier.scheduled, hasLength(1));
      expect(notifier.scheduleCalls, 1);
    });

    test('cancellation removes the reminder; a date change reschedules it', () async {
      await scheduler.syncAll('user-1', [booking(_uuidA), booking(_uuidB)]);
      await scheduler.bookingChanged('user-1', booking(_uuidA, status: 'cancelled'));
      expect(notifier.scheduled.keys, [idOf(_uuidB)]);

      await scheduler.bookingChanged('user-1', booking(_uuidB, travelDate: '2026-12-20'));
      expect(notifier.scheduled[idOf(_uuidB)]!.at, DateTime(2026, 12, 19, 9).toUtc());
      expect(notifier.scheduled, hasLength(1));
    });

    test('a booking missing from the full list loses its reminder', () async {
      await scheduler.syncAll('user-1', [booking(_uuidA), booking(_uuidB)]);
      await scheduler.syncAll('user-1', [booking(_uuidB)]);
      expect(notifier.scheduled.keys, [idOf(_uuidB)]);
    });

    test('turning reminders off removes them; on restores them without a network call', () async {
      await scheduler.syncAll('user-1', [booking(_uuidA)]);
      enabled = false;
      await scheduler.resync();
      expect(notifier.scheduled, isEmpty);
      enabled = true;
      await scheduler.resync();
      expect(notifier.scheduled, hasLength(1));
    });

    test('a language change rebuilds the text in Arabic', () async {
      await scheduler.syncAll('user-1', [booking(_uuidA)]);
      locale = const Locale('ar');
      await scheduler.resync();
      final r = notifier.scheduled[idOf(_uuidA)]!;
      expect(r.title, 'رحلتك إلى القاهرة غدًا');
      expect(r.body, contains('عطلة'));
      expect(notifier.scheduleCalls, 2);
    });

    test('sign-out clears everything; another user starts clean; stale results are ignored', () async {
      await scheduler.syncAll('user-1', [booking(_uuidA)]);
      await scheduler.clear();
      expect(notifier.scheduled, isEmpty);

      await scheduler.syncAll('user-1', [booking(_uuidA)]); // late result after sign-out
      expect(notifier.scheduled, isEmpty);

      await scheduler.activate('user-2');
      await scheduler.syncAll('user-1', [booking(_uuidA)]);
      expect(notifier.scheduled, isEmpty, reason: 'user-1 results never schedule for user-2');
      await scheduler.syncAll('user-2', [booking(_uuidB)]);
      expect(notifier.scheduled.keys, [idOf(_uuidB)]);

      await scheduler.activate('user-3');
      expect(notifier.scheduled, isEmpty, reason: 'switching accounts drops the previous user\'s reminders');
    });

    test('a scheduling failure is contained and later operations still run', () async {
      notifier.failSchedule = true;
      await scheduler.syncAll('user-1', [booking(_uuidA)]);
      expect(notifier.scheduled, isEmpty);
      notifier.failSchedule = false;
      await scheduler.syncAll('user-1', [booking(_uuidA)]);
      expect(notifier.scheduled, hasLength(1));
    });

    test('unsupported platform: nothing is scheduled or read', () async {
      final off = FakeLocalReminderNotifier(supported: false);
      final s = TripReminderScheduler(off, enabled: () => true, locale: () => locale, now: () => now);
      await s.activate('user-1');
      await s.syncAll('user-1', [booking(_uuidA)]);
      expect(off.scheduleCalls, 0);
    });

    test('non-reminder notifications are left alone', () async {
      await notifier.schedule(
          id: 7, at: now, title: 't', body: 'b', payload: 'other', channelName: 'c', channelDescription: 'd');
      await scheduler.syncAll('user-1', []);
      await scheduler.clear();
      expect(notifier.scheduled.keys, [7]);
    });
  });

  group('ReminderSyncingBookingRepository', () {
    test('create schedules, cancel removes, list reconciles; failures schedule nothing', () async {
      final today = DateTime(2026, 10);
      final notifier = FakeLocalReminderNotifier();
      await notifier.initialize();
      final scheduler = TripReminderScheduler(notifier,
          enabled: () => true, locale: () => const Locale('en'), now: () => DateTime(2026, 10, 1, 12));
      await scheduler.activate('user-1');
      final inner = FakeBookingRepository(today: today);
      final repo = ReminderSyncingBookingRepository(inner, scheduler, currentUserId: () => 'user-1');

      inner.nextCreateFailure = const AppFailure(FailureType.network);
      final request = BookingRequest(
        destinationId: 'id-cairo',
        packageId: 'pkg-1',
        travelDate: DateTime(2026, 10, 20),
        travelers: 2,
        contactName: 'Sara Ali',
        contactPhone: '+20 100 000 0000',
      );
      await expectLater(repo.createBooking(request), throwsA(isA<AppFailure>()));
      await pumpEventQueue();
      expect(notifier.scheduled, isEmpty, reason: 'no reminder without a stored booking');

      final created = await repo.createBooking(request);
      await pumpEventQueue();
      expect(notifier.scheduled[TripReminderPolicy.notificationId(created.id)]!.at, DateTime(2026, 10, 19, 9).toUtc());

      await repo.cancelBooking(created.id);
      await pumpEventQueue();
      expect(notifier.scheduled, isEmpty);

      final seeded = inner.seed(userId: 'user-1', travelDate: DateTime(2026, 11, 2));
      await repo.fetchMyBookings();
      await pumpEventQueue();
      expect(notifier.scheduled.keys, [TripReminderPolicy.notificationId(seeded.id)]);
    });
  });

  group('PushTokenSync', () {
    late String? currentUser;
    late FakePushMessaging push;
    late FakeDeviceTokenRepository tokens;
    late PushTokenSync sync;

    setUp(() async {
      currentUser = 'user-1';
      push = FakePushMessaging();
      await push.initialize();
      tokens = FakeDeviceTokenRepository(currentUserId: () => currentUser);
      sync = PushTokenSync(push, tokens)..start();
    });
    tearDown(() => sync.dispose());

    test('registers once per (token, user)', () async {
      expect(await sync.attach('user-1'), isTrue);
      expect(await sync.attach('user-1'), isTrue);
      expect(tokens.calls, ['register:user-1']);
      expect(tokens.tokensOf('user-1'), [FakePushMessaging.defaultToken]);
      expect(tokens.rows[FakePushMessaging.defaultToken]!.platform, DevicePlatform.android);
    });

    test('token refresh registers the new token and removes the old one', () async {
      await sync.attach('user-1');
      push.refreshToken('fcm-token-BBBBBBBBBBBBBBBBBBBBBBBBBBBB');
      await pumpEventQueue();
      expect(tokens.tokensOf('user-1'), ['fcm-token-BBBBBBBBBBBBBBBBBBBBBBBBBBBB']);
      expect(sync.registeredToken, 'fcm-token-BBBBBBBBBBBBBBBBBBBBBBBBBBBB');
    });

    test('refresh while signed out registers nothing', () async {
      push.refreshToken('fcm-token-CCCCCCCCCCCCCCCCCCCCCCCCCCCC');
      await pumpEventQueue();
      expect(tokens.calls, isEmpty);
    });

    test('detach unregisters with the session still valid', () async {
      await sync.attach('user-1');
      await sync.detach();
      expect(tokens.rows, isEmpty);
      expect(sync.registeredToken, isNull);
    });

    test('account switch moves the token to the new user only', () async {
      await sync.attach('user-1');
      currentUser = 'user-2';
      await sync.attach('user-2');
      expect(tokens.tokensOf('user-1'), isEmpty);
      expect(tokens.tokensOf('user-2'), [FakePushMessaging.defaultToken]);
    });

    test('push unavailable or registration failure', () async {
      final off = PushTokenSync(FakePushMessaging(available: false), tokens);
      expect(await off.attach('user-1'), isFalse);
      expect(tokens.calls, isEmpty);

      tokens.nextFailure = const AppFailure(FailureType.network);
      expect(await sync.attach('user-1'), isFalse);
      expect(await sync.attach('user-1'), isTrue, reason: 'retried on the next attach');
    });
  });

  group('SupabaseDeviceTokenRepository', () {
    late List<http.Request> requests;
    late SupabaseClient client;
    late String? signedIn;
    late SupabaseDeviceTokenRepository repo;

    setUp(() {
      requests = [];
      signedIn = 'u1';
      client = SupabaseClient(
        'https://test-project.supabase.co',
        'sb_publishable_test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          return http.Response('', 204, request: r);
        }),
      );
      repo = SupabaseDeviceTokenRepository(client, currentUserId: () => signedIn);
    });
    tearDown(() => client.dispose());

    test('uses only the database functions; never sends a user id', () async {
      await repo.register(FakePushMessaging.defaultToken, DevicePlatform.android);
      await repo.unregister(FakePushMessaging.defaultToken);
      expect(requests.map((r) => r.url.path),
          ['/rest/v1/rpc/register_device_token', '/rest/v1/rpc/unregister_device_token']);
      expect(jsonDecode(requests.first.body), {'p_token': FakePushMessaging.defaultToken, 'p_platform': 'android'});
      expect(requests.first.body, isNot(contains('user_id')));
    });

    test('no session or an invalid token sends nothing', () async {
      await expectLater(repo.register('short', DevicePlatform.ios),
          throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.invalidInput)));
      signedIn = null;
      await expectLater(repo.register(FakePushMessaging.defaultToken, DevicePlatform.ios),
          throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.sessionExpired)));
      expect(requests, isEmpty);
    });
  });

  group('DeviceNotificationsCubit', () {
    const otherUser = AppUser(id: 'user-2', email: 'other@example.com', emailConfirmed: true);
    late FakeAuthRepository auth;
    late SessionCubit session;
    late FakeLocalReminderNotifier notifier;
    late FakePushMessaging push;
    late FakeDeviceTokenRepository tokens;
    late FakeBookingRepository inner;
    late AppPreferences prefs;
    late TripReminderScheduler scheduler;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = AppPreferences(await SharedPreferences.getInstance());
      auth = FakeAuthRepository(signedInAs: testUser);
      session = SessionCubit(auth);
      notifier = FakeLocalReminderNotifier();
      push = FakePushMessaging();
      tokens = FakeDeviceTokenRepository(currentUserId: () => auth.currentUser?.id);
      inner = FakeBookingRepository(currentUserId: () => auth.currentUser?.id, today: DateTime(2026, 10));
      scheduler = TripReminderScheduler(notifier,
          enabled: () => prefs.tripRemindersEnabled,
          locale: () => const Locale('en'),
          now: () => DateTime(2026, 10, 1, 12));
    });

    tearDown(() async {
      await session.close();
      await auth.dispose();
    });

    DeviceNotificationsCubit build() => DeviceNotificationsCubit(
          notifier: notifier,
          push: push,
          tokenSync: PushTokenSync(push, tokens),
          reminders: scheduler,
          bookings: ReminderSyncingBookingRepository(inner, scheduler, currentUserId: () => auth.currentUser?.id),
          session: session,
          preferences: prefs,
        );

    test('startup: resyncs reminders from the user\'s bookings once', () async {
      final mine = inner.seed(userId: testUser.id, travelDate: DateTime(2026, 11, 2));
      inner.seed(userId: testUser.id, travelDate: DateTime(2026, 11, 9), status: BookingStatus.cancelled);
      inner.seed(userId: 'user-2', travelDate: DateTime(2026, 11, 5));
      final cubit = build();
      await cubit.start();
      await pumpEventQueue();
      expect(cubit.state.remindersSupported, isTrue);
      expect(inner.calls.where((c) => c.startsWith('list')), ['list:user-1']);
      expect(notifier.scheduled.keys, [TripReminderPolicy.notificationId(mine.id)]);
      await cubit.close();
    });

    test('permission: not asked at launch, asked once after booking, never again', () async {
      final cubit = build();
      await cubit.start();
      expect(cubit.state.permission, NotificationPermission.notDetermined);
      expect(notifier.permissionRequests, 0);
      expect(tokens.calls, isEmpty, reason: 'no token registration without permission');

      await cubit.requestPermissionAfterBooking();
      await cubit.requestPermissionAfterBooking();
      expect(notifier.permissionRequests, 1);
      expect(cubit.state.permission, NotificationPermission.granted);
      expect(tokens.tokensOf(testUser.id), [FakePushMessaging.defaultToken]);
      expect(cubit.state.tokenRegistered, isTrue);
      await cubit.close();
    });

    test('a refused prompt is reported; later the OS-level change is picked up on resume', () async {
      notifier.grantOnRequest = false;
      final cubit = build();
      await cubit.start();
      await cubit.requestPermission();
      expect(cubit.state.permission, NotificationPermission.denied);
      expect(cubit.state.deniedSerial, 1);
      expect(tokens.calls, isEmpty);

      // Reopened: denied stays denied (not "not determined"), no re-prompt.
      final again = build();
      await again.start();
      expect(again.state.permission, NotificationPermission.denied);
      await again.requestPermissionAfterBooking();
      expect(notifier.permissionRequests, 1);

      notifier.osPermission = NotificationPermission.granted; // user enabled it in system settings
      await again.refreshPermission();
      expect(again.state.permission, NotificationPermission.granted);
      expect(tokens.tokensOf(testUser.id), hasLength(1));
      await cubit.close();
      await again.close();
    });

    test('sign-out unregisters the token first, then removes reminders', () async {
      notifier.osPermission = NotificationPermission.granted;
      inner.seed(userId: testUser.id, travelDate: DateTime(2026, 11, 2));
      final cubit = build();
      await cubit.start();
      await pumpEventQueue();
      expect(tokens.rows, hasLength(1));
      expect(notifier.scheduled, hasLength(1));

      await session.signOut();
      await pumpEventQueue();
      expect(tokens.calls.last, 'unregister:user-1', reason: 'while the session was still valid');
      expect(tokens.rows, isEmpty);
      expect(notifier.scheduled, isEmpty);
      expect(cubit.state.tokenRegistered, isFalse);
      await cubit.close();
    });

    test('account switch: reminders and token follow the new user only', () async {
      notifier.osPermission = NotificationPermission.granted;
      inner.seed(userId: testUser.id, travelDate: DateTime(2026, 11, 2));
      final theirs = inner.seed(userId: 'user-2', travelDate: DateTime(2026, 12, 2));
      final cubit = build();
      await cubit.start();
      await pumpEventQueue();

      auth.switchTo(otherUser);
      await pumpEventQueue();
      expect(notifier.scheduled.keys, [TripReminderPolicy.notificationId(theirs.id)]);
      expect(tokens.tokensOf(testUser.id), isEmpty);
      expect(tokens.tokensOf('user-2'), [FakePushMessaging.defaultToken]);
      await cubit.close();
    });

    test('taps open only real booking ids; pushes refresh instead of showing a banner', () async {
      notifier.launch =
          TripReminderPayload(bookingId: _uuidA, at: DateTime(2026, 11, 1, 9), languageCode: 'en').encode();
      push.initial = const PushMessage(type: 'booking_cancelled', bookingId: _uuidB);
      final cubit = build();
      final opened = <String>[];
      var foreground = 0;
      cubit.openBookingRequests.listen(opened.add);
      cubit.foregroundPushes.listen((_) => foreground++);
      await cubit.start();

      notifier.tap(TripReminderPayload(bookingId: _uuidC, at: DateTime(2026, 11, 1, 9), languageCode: 'en').encode());
      notifier.tap('not json');
      notifier.tap(TripReminderPayload(bookingId: 'bk-1', at: DateTime(2026, 11, 1, 9), languageCode: 'en').encode());
      push.open(const PushMessage(bookingId: _uuidA));
      push.open(const PushMessage(bookingId: '../../etc'));
      push.receiveForeground(const PushMessage(type: 'booking_confirmed', bookingId: _uuidA));
      await pumpEventQueue();

      expect(opened, [_uuidA, _uuidB, _uuidC, _uuidA]);
      expect(foreground, 1);
      expect(notifier.scheduled, isEmpty, reason: 'a push never creates a local notification');
      await cubit.close();
    });

    test('Firebase unavailable: reminders still work, push stays off', () async {
      push = FakePushMessaging(available: false);
      notifier.osPermission = NotificationPermission.granted;
      inner.seed(userId: testUser.id, travelDate: DateTime(2026, 11, 2));
      final cubit = build();
      await cubit.start();
      await pumpEventQueue();
      expect(cubit.state.pushAvailable, isFalse);
      expect(tokens.calls, isEmpty);
      expect(notifier.scheduled, hasLength(1));
      await cubit.close();
    });

    test('unsupported platform (web): nothing initialises, nothing is fetched', () async {
      notifier = FakeLocalReminderNotifier(supported: false);
      push = FakePushMessaging(available: false);
      scheduler = TripReminderScheduler(notifier, enabled: () => true, locale: () => const Locale('en'));
      final cubit = build();
      await cubit.start();
      await cubit.requestPermission();
      await cubit.setRemindersEnabled(false);
      expect(cubit.state.remindersSupported, isFalse);
      expect(cubit.state.permission, NotificationPermission.unsupported);
      expect(inner.calls, isEmpty);
      expect(prefs.tripRemindersEnabled, isTrue, reason: 'the preference only changes where it applies');
      await cubit.close();
    });

    test('switching reminders off removes them and is remembered', () async {
      inner.seed(userId: testUser.id, travelDate: DateTime(2026, 11, 2));
      final cubit = build();
      await cubit.start();
      await pumpEventQueue();
      await cubit.setRemindersEnabled(false);
      expect(notifier.scheduled, isEmpty);
      expect(prefs.tripRemindersEnabled, isFalse);
      await cubit.setRemindersEnabled(true);
      await pumpEventQueue();
      expect(notifier.scheduled, hasLength(1));
      await cubit.close();
    });

    test('creates the booking-updates channel in the app language and renames it on a change', () async {
      var lang = 'en';
      final cubit = DeviceNotificationsCubit(
        notifier: notifier,
        push: push,
        tokenSync: PushTokenSync(push, tokens),
        reminders: scheduler,
        bookings: ReminderSyncingBookingRepository(inner, scheduler, currentUserId: () => auth.currentUser?.id),
        session: session,
        preferences: prefs,
        locale: () => Locale(lang),
      );
      await cubit.start();
      expect(notifier.bookingUpdatesChannel?.name, 'Booking updates');
      lang = 'ar';
      await cubit.languageChanged();
      expect(notifier.bookingUpdatesChannel?.name, 'تحديثات الحجز');
      await cubit.close();
    });

    test('a failed registration is retried when the app resumes', () async {
      notifier.osPermission = NotificationPermission.granted;
      tokens.nextFailure = const AppFailure(FailureType.network);
      final cubit = build();
      await cubit.start();
      expect(cubit.state.tokenRegistered, isFalse);
      await cubit.refreshPermission();
      expect(cubit.state.tokenRegistered, isTrue);
      expect(tokens.tokensOf(testUser.id), [FakePushMessaging.defaultToken]);
      await cubit.refreshPermission();
      expect(tokens.calls.where((c) => c.startsWith('register')), hasLength(2), reason: 'no re-register once done');
      await cubit.close();
    });

    test('foreground pushes are passed on with their data, never turned into local notifications', () async {
      final cubit = build();
      final received = <PushMessage>[];
      cubit.foregroundPushes.listen(received.add);
      await cubit.start();
      push.receiveForeground(const PushMessage(type: 'booking_confirmed', bookingId: _uuidA, reference: 'RH-3F9A1C2B'));
      await pumpEventQueue();
      expect(received.single.reference, 'RH-3F9A1C2B');
      expect(notifier.scheduleCalls, 0);
      await cubit.close();
    });
  });
}
