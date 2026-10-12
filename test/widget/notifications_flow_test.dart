import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/app_notification.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_notifications_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  const otherUser = AppUser(id: 'user-2', email: 'other@example.com', fullName: 'Omar Nabil', emailConfirmed: true);

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Finder badgeWith(String label) => find.descendant(of: find.byType(Badge), matching: find.text(label));

  group('Notifications', () {
    testWidgets('Profile badge → list → tap marks read on the server and opens the booking', (tester) async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final bookings = FakeBookingRepository(currentUserId: () => auth.currentUser?.id);
      final booking = bookings.seed(userId: testUser.id);
      final notifications = FakeNotificationsRepository(currentUserId: () => auth.currentUser?.id)
        ..add(userId: testUser.id, bookingId: booking.id, reference: booking.reference)
        ..add(userId: testUser.id, type: NotificationType.bookingCancelled, bookingId: null, read: true);
      await pumpApp(tester,
          repo: auth, bookings: bookings, notifications: notifications, initialLocation: AppRoutes.account);

      await scrollTo(tester, find.text('Notifications'));
      expect(find.text('1 unread notification'), findsOneWidget);
      expect(badgeWith('1'), findsOneWidget);

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Booking confirmed'), findsOneWidget);
      expect(find.text('Booking cancelled'), findsOneWidget);
      expect(find.textContaining('Cairo on'), findsNWidgets(2));
      expect(find.textContaining(booking.reference), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);

      await tester.tap(find.text('Booking confirmed'));
      await tester.pumpAndSettle();
      expect(notifications.calls, contains(startsWith('mark:')));
      expect(find.text('Booking details'), findsOneWidget);
      expect(find.text(booking.reference), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unread-dot')), findsNothing, reason: 'read state confirmed by the server');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('No unread notifications'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
      expect(badgeWith('1'), findsNothing);
    });

    testWidgets('a notification without a booking is marked read but opens nothing', (tester) async {
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id)
        ..add(userId: testUser.id, bookingId: null);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          notifications: notifications,
          initialLocation: AppRoutes.notifications);
      await tester.tap(find.text('Booking confirmed'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
    });

    testWidgets('mark all as read', (tester) async {
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id)
        ..add(userId: testUser.id)
        ..add(userId: testUser.id);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          notifications: notifications,
          initialLocation: AppRoutes.notifications);
      expect(find.byKey(const ValueKey('unread-dot')), findsNWidgets(2));
      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pumpAndSettle();
      expect(notifications.calls, contains('markAll'));
      expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
    });

    testWidgets('a failed mark-read leaves it unread and says so', (tester) async {
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id)
        ..add(userId: testUser.id, bookingId: null)
        ..nextMarkFailure = const AppFailure(FailureType.network);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          notifications: notifications,
          initialLocation: AppRoutes.notifications);
      await tester.tap(find.text('Booking confirmed'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);
      expect(find.textContaining("Couldn't update notifications."), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pumpApp(tester, repo: FakeAuthRepository(signedInAs: testUser), initialLocation: AppRoutes.notifications);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.byTooltip('Mark all as read'), findsNothing);
    });

    testWidgets('error, then retry', (tester) async {
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id)
        ..add(userId: testUser.id)
        ..nextLoadFailure = const AppFailure(FailureType.network);
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          notifications: notifications,
          initialLocation: AppRoutes.notifications);
      expect(find.text("Couldn't load notifications"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Booking confirmed'), findsOneWidget);
    });

    testWidgets('sign-out clears them; another account sees only its own', (tester) async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final notifications = FakeNotificationsRepository(currentUserId: () => auth.currentUser?.id)
        ..add(userId: testUser.id, reference: 'RH-MINE0001')
        ..add(userId: otherUser.id, reference: 'RH-THEIRS01');
      await pumpApp(tester, repo: auth, notifications: notifications, initialLocation: AppRoutes.notifications);
      expect(find.textContaining('RH-MINE0001'), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.textContaining('RH-MINE0001'), findsNothing);

      auth.switchTo(otherUser);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Notifications'));
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.textContaining('RH-THEIRS01'), findsOneWidget);
      expect(find.textContaining('RH-MINE0001'), findsNothing);
    });

    testWidgets('requires sign-in', (tester) async {
      await pumpApp(tester, initialLocation: AppRoutes.notifications);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Arabic, right-to-left, with the stored Arabic destination name', (tester) async {
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id)
        ..add(userId: testUser.id)
        ..add(userId: testUser.id, type: NotificationType.bookingCancelled);
      await pumpApp(
        tester,
        repo: FakeAuthRepository(signedInAs: testUser),
        notifications: notifications,
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.account,
      );
      await scrollTo(tester, find.text('الإشعارات'));
      expect(find.text('إشعاران غير مقروءين'), findsOneWidget, reason: 'Arabic dual');

      await tester.tap(find.text('الإشعارات'));
      await tester.pumpAndSettle();
      expect(Directionality.of(tester.element(find.text('تم تأكيد الحجز'))), TextDirection.rtl);
      expect(find.text('تم إلغاء الحجز'), findsOneWidget);
      expect(find.textContaining('القاهرة بتاريخ'), findsNWidgets(2));
      expect(find.byTooltip('تعليم الكل كمقروء'), findsOneWidget);
    });
  });

  group('Booking idempotency in the UI', () {
    testWidgets('a lost response then "Confirm" again shows the one booking that exists', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)..loseNextCreateResponse = true;
      await pumpApp(tester,
          repo: FakeAuthRepository(signedInAs: testUser),
          bookings: bookings,
          initialLocation: AppRoutes.book('id-cairo', packageId: 'pkg-1'));

      await scrollTo(tester, find.text('Choose a date'));
      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.widgetWithText(TextFormField, 'Phone number'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), '+20 100 000 0000');
      await scrollTo(tester, find.text('Review booking'));
      await tester.tap(find.text('Review booking'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Confirm booking'));
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();
      expect(find.text('Booking confirmed'), findsNothing, reason: 'the app never claims an unconfirmed booking');
      expect(bookings.countFor(testUser.id), 1);

      await scrollTo(tester, find.text('Confirm booking'));
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();
      expect(find.text('Booking confirmed'), findsOneWidget);
      expect(find.text(bookings.storedBooking('bk-1').reference), findsOneWidget);
      expect(bookings.countFor(testUser.id), 1);
      expect(bookings.requests.map((r) => r.clientRequestId).toSet(), hasLength(1));
    });
  });
}
