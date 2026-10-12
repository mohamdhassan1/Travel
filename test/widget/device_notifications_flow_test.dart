import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/notifications/local_reminder_notifier.dart';
import 'package:rahala/data/notifications/push_messaging.dart';
import 'package:rahala/logic/notifications/trip_reminder_policy.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_device_notifications.dart';
import '../helpers/fake_notifications_repository.dart';
import '../helpers/pump_app.dart';

const _uuidA = '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90';
const _uuidMissing = '9f9f9f9f-1111-4222-8333-444444444444';

String _reminder(String bookingId) =>
    TripReminderPayload(bookingId: bookingId, at: DateTime(2026, 11, 1, 9), languageCode: 'en').encode();

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  group('Settings → Notifications', () {
    testWidgets('platform without notifications (e.g. web) says so honestly', (tester) async {
      await pumpApp(tester, repo: FakeAuthRepository(signedInAs: testUser), initialLocation: AppRoutes.settings);
      await scrollTo(tester, find.text('Trip reminders'));
      expect(find.textContaining("aren't available on this platform"), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('not yet asked: Allow requests permission once', (tester) async {
      final notifier = FakeLocalReminderNotifier();
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser), localNotifier: notifier, initialLocation: AppRoutes.settings);
      await scrollTo(tester, find.text('Allow'));
      expect(find.text('Allow notifications so trip reminders can appear.'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(notifier.permissionRequests, 1);
      expect(find.text('Allow'), findsNothing);
    });

    testWidgets('refused: message, then "Open settings" opens the system page', (tester) async {
      final notifier = FakeLocalReminderNotifier(grantOnRequest: false);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser), localNotifier: notifier, initialLocation: AppRoutes.settings);
      await scrollTo(tester, find.text('Allow'));
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(find.textContaining("Notifications weren't allowed"), findsOneWidget);
      await scrollTo(tester, find.text('Open settings'));
      expect(find.textContaining('turned off for Rahala'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      expect(notifier.settingsOpened, 1);
    });

    testWidgets('switch off removes scheduled reminders; on restores them', (tester) async {
      final notifier = FakeLocalReminderNotifier(osPermission: NotificationPermission.granted);
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          bookings: bookings,
          localNotifier: notifier,
          initialLocation: AppRoutes.settings);
      expect(notifier.scheduled.keys, [TripReminderPolicy.notificationId(mine.id)], reason: 'startup resync');

      await scrollTo(tester, find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(notifier.scheduled, isEmpty);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(notifier.scheduled, hasLength(1));
    });

    testWidgets('Arabic, right-to-left', (tester) async {
      await pumpApp(
        tester,
        repo: FakeAuthRepository(signedInAs: testUser),
        localNotifier: FakeLocalReminderNotifier(),
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.settings,
      );
      await scrollTo(tester, find.text('تذكيرات الرحلات'));
      expect(Directionality.of(tester.element(find.text('تذكيرات الرحلات'))), TextDirection.rtl);
      expect(find.text('سماح'), findsOneWidget);
    });
  });

  group('Reminders and the booking lifecycle', () {
    testWidgets('cancelling a booking removes its reminder', (tester) async {
      final notifier = FakeLocalReminderNotifier(osPermission: NotificationPermission.granted);
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id, id: _uuidA);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          bookings: bookings,
          localNotifier: notifier,
          initialLocation: AppRoutes.booking(mine.id));
      expect(notifier.scheduled, hasLength(1));

      await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      expect(bookings.storedBooking(mine.id).isCancelled, isTrue);
      expect(notifier.scheduled, isEmpty);
    });

    testWidgets('signing out removes every reminder and unregisters the token', (tester) async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final notifier = FakeLocalReminderNotifier(osPermission: NotificationPermission.granted);
      final tokens = FakeDeviceTokenRepository(currentUserId: () => auth.currentUser?.id);
      final bookings = FakeBookingRepository(currentUserId: () => auth.currentUser?.id)..seed(userId: testUser.id);
      await pumpApp(tester,
          repo: auth,
          bookings: bookings,
          localNotifier: notifier,
          push: FakePushMessaging(),
          deviceTokens: tokens,
          initialLocation: AppRoutes.account);
      expect(notifier.scheduled, hasLength(1));
      expect(tokens.tokensOf(testUser.id), hasLength(1));

      await scrollTo(tester, find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(tokens.rows, isEmpty);
      expect(notifier.scheduled, isEmpty);
    });
  });

  group('Tapping a reminder or push', () {
    testWidgets('opens the booking details', (tester) async {
      final notifier = FakeLocalReminderNotifier(osPermission: NotificationPermission.granted);
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id, id: _uuidA);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser), bookings: bookings, localNotifier: notifier);
      notifier.tap(_reminder(mine.id));
      await tester.pumpAndSettle();
      expect(find.text('Booking details'), findsOneWidget);
      expect(find.text(mine.reference), findsOneWidget);
    });

    testWidgets('launch from a reminder (app was terminated) opens the booking', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id, id: _uuidA);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          bookings: bookings,
          localNotifier: FakeLocalReminderNotifier(launch: _reminder(mine.id)));
      expect(find.text('Booking details'), findsOneWidget);
    });

    testWidgets('a deleted / unknown booking shows "not found", not a crash', (tester) async {
      final notifier = FakeLocalReminderNotifier();
      await pumpApp(tester, repo: FakeAuthRepository(signedInAs: testUser), localNotifier: notifier);
      notifier.tap(_reminder(_uuidMissing));
      await tester.pumpAndSettle();
      expect(find.text('Booking not found'), findsOneWidget);
    });

    testWidgets('a cancelled booking opens showing its cancelled status', (tester) async {
      final push = FakePushMessaging();
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      bookings.seed(userId: testUser.id, id: _uuidA, status: BookingStatus.cancelled);
      await pumpApp(tester, repo: FakeAuthRepository(signedInAs: testUser), bookings: bookings, push: push);
      push.open(const PushMessage(type: 'booking_cancelled', bookingId: _uuidA));
      await tester.pumpAndSettle();
      expect(find.text('Booking details'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel booking'), findsNothing);
    });

    testWidgets('signed out: goes through login (protected route)', (tester) async {
      final notifier = FakeLocalReminderNotifier();
      await pumpApp(tester, localNotifier: notifier);
      notifier.tap(_reminder(_uuidA));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Booking details'), findsNothing);
    });

    testWidgets('malformed payloads are ignored', (tester) async {
      final notifier = FakeLocalReminderNotifier();
      await pumpApp(tester, repo: FakeAuthRepository(signedInAs: testUser), localNotifier: notifier);
      notifier
        ..tap('garbage')
        ..tap(_reminder('bk-1'))
        ..tap(null);
      await tester.pumpAndSettle();
      expect(find.text('Booking details'), findsNothing);
      expect(find.text('Booking not found'), findsNothing);
    });
  });

  group('Remote push while the app is open', () {
    testWidgets('one in-app message (no system banner), list refreshed, View opens the booking', (tester) async {
      final push = FakePushMessaging();
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id, id: _uuidA);
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id);
      final notifier = FakeLocalReminderNotifier();
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          bookings: bookings,
          notifications: notifications,
          localNotifier: notifier,
          push: push);
      final loadsBefore = notifications.calls.length;
      final localBefore = notifier.scheduleCalls;

      push.receiveForeground(PushMessage(type: 'booking_confirmed', bookingId: mine.id, reference: 'RH-3F9A1C2B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750)); // SnackBar entrance
      expect(find.text('Booking confirmed · RH-3F9A1C2B'), findsOneWidget);
      expect(notifications.calls.length, greaterThan(loadsBefore), reason: 'server notifications refreshed');
      expect(notifier.scheduleCalls, localBefore, reason: 'no duplicate local notification');

      expect(find.text('View'), findsOneWidget);
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pumpAndSettle();
      expect(find.text('Booking details'), findsOneWidget);
    });

    testWidgets('a push without a valid booking id offers no navigation', (tester) async {
      final push = FakePushMessaging();
      await pumpApp(tester, repo: FakeAuthRepository(signedInAs: testUser), push: push);
      push.receiveForeground(const PushMessage(type: 'booking_cancelled', bookingId: 'not-a-uuid'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750)); // SnackBar entrance
      expect(find.text('Booking cancelled'), findsOneWidget);
      expect(find.text('View'), findsNothing);
    });
  });

  group('Settings → Booking updates (push)', () {
    Future<void> openSettings(WidgetTester tester,
        {required FakePushMessaging push, FakeLocalReminderNotifier? n}) async {
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          localNotifier: n ?? FakeLocalReminderNotifier(osPermission: NotificationPermission.granted),
          push: push,
          initialLocation: AppRoutes.settings);
      await scrollTo(tester, find.text('Booking updates'));
    }

    testWidgets('registered device', (tester) async {
      await openSettings(tester, push: FakePushMessaging());
      expect(find.text('Confirmations and cancellations are sent to this device.'), findsOneWidget);
    });

    testWidgets('Firebase not configured on this device', (tester) async {
      await openSettings(tester, push: FakePushMessaging(available: false));
      expect(find.text("Push notifications aren't set up for this device yet."), findsOneWidget);
    });

    testWidgets('permission not granted yet', (tester) async {
      await openSettings(tester, push: FakePushMessaging(), n: FakeLocalReminderNotifier());
      expect(find.text('Allow notifications to get booking updates on this device.'), findsOneWidget);
    });
  });
}
