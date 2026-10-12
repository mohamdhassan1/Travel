import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/data/models/app_notification.dart';
import 'package:rahala/logic/notifications/notifications_cubit.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_notifications_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(signedInAs: testUser);

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  group('Notifications stay current after booking changes', () {
    testWidgets('cancelling refreshes the in-app notifications (no push needed)', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id);
      final notifications = FakeNotificationsRepository(currentUserId: () => testUser.id);
      await pumpApp(
        tester,
        repo: signedIn(),
        bookings: bookings,
        notifications: notifications,
        initialLocation: AppRoutes.booking(mine.id),
      );
      final cubit = BlocProvider.of<NotificationsCubit>(tester.element(find.byType(Scaffold).first));
      expect(cubit.state.unreadCount, 0);

      // What the database trigger writes in the same transaction as the cancel.
      notifications.add(userId: testUser.id, type: NotificationType.bookingCancelled, bookingId: mine.id);
      await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();

      expect(cubit.state.unreadCount, 1, reason: 'the bell/badge shows the new notification right away');
    });
  });

  group('Signed-out language switch', () {
    testWidgets('login offers the other language and switches the whole UI to RTL', (tester) async {
      await pumpApp(tester);
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget, reason: 'the toggle now offers the way back');
      expect(Directionality.of(tester.element(find.byType(Form))), TextDirection.rtl);
    });

    testWidgets('screens with a back button show it in the app bar', (tester) async {
      await pumpApp(tester, initialLocation: AppRoutes.forgotPassword);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('العربية')), findsOneWidget);
    });
  });
}
