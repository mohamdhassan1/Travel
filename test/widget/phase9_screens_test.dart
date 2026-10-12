import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/booking.dart' show serverToday;
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/presentation/catalog/widgets/photo_viewer.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_data_repositories.dart';
import '../helpers/pump_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(signedInAs: testUser);

  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    // Lazily built lists: scroll until the target exists, then reveal it.
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('Delete account', () {
    testWidgets('needs explicit confirmation, deletes on the server, then lands on sign-in', (tester) async {
      final account = FakeAccountRepository();
      final auth = await pumpApp(tester, repo: signedIn(), account: account, initialLocation: AppRoutes.account);

      await tapVisible(tester, find.text('Delete account'));
      expect(find.text('Delete your account?'), findsOneWidget);
      final confirm = find.widgetWithText(FilledButton, 'Delete permanently');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull, reason: 'disabled until acknowledged');

      await tester.tap(find.text("I understand this can't be undone"));
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(account.deleted, 1);
      expect(auth.currentUser, isNull);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Your account has been deleted.'), findsOneWidget);
    });

    testWidgets('cancelling changes nothing', (tester) async {
      final account = FakeAccountRepository();
      await pumpApp(tester, repo: signedIn(), account: account, initialLocation: AppRoutes.account);
      await tapVisible(tester, find.text('Delete account'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(account.calls, 0);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('a refused deletion keeps the user signed in and says why', (tester) async {
      final account = FakeAccountRepository(failure: const AppFailure(FailureType.network));
      final auth = await pumpApp(tester, repo: signedIn(), account: account, initialLocation: AppRoutes.account);
      await tapVisible(tester, find.text('Delete account'));
      await tester.tap(find.text("I understand this can't be undone"));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete permanently'));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNotNull);
      expect(find.textContaining("Couldn't delete your account."), findsOneWidget);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('Arabic: the dialog is translated and right-to-left', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(),
        initialLocation: AppRoutes.account,
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
      );
      await tapVisible(tester, find.text('حذف الحساب'));
      expect(find.text('حذف حسابك؟'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('حذف حسابك؟'))), TextDirection.rtl);
    });
  });

  group('Change password', () {
    testWidgets('reachable from Settings, can go back, updates through the auth server', (tester) async {
      final auth = await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.settings);
      await tapVisible(tester, find.text('Change password'));
      expect(find.text('Change your password'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget, reason: 'not a recovery session: the user may leave');

      await tester.enterText(field('New password'), 'Travel2026x');
      await tester.enterText(field('Confirm password'), 'Travel2026x');
      await tester.pump();
      await tapVisible(tester, find.text('Update password'));

      expect(auth.calls, contains('updatePassword'));
      expect(find.text('Your password has been updated.'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget, reason: 'back on Settings');
    });
  });

  group('Booking flow polish', () {
    testWidgets('the booking form starts with the profile phone', (tester) async {
      final profile = FakeProfileRepository(
        profile: const UserProfile(id: 'user-1', fullName: 'Sara Ali', phone: '+20 100 123 4567'),
      );
      await pumpApp(tester, repo: signedIn(), profile: profile, initialLocation: AppRoutes.book('id-cairo'));
      final phone = tester.widget<TextFormField>(field('Phone number'));
      expect(phone.controller?.text, '+20 100 123 4567');
    });

    testWidgets('confirmation that fails to load is never a dead end', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final booking = bookings.seed(userId: testUser.id);
      // Every single-booking read fails (the details page under the
      // confirmation reads it too); the Trips list still loads.
      bookings.getFailure = const AppFailure(FailureType.network);
      await pumpApp(
        tester,
        repo: signedIn(),
        bookings: bookings,
        initialLocation: AppRoutes.bookingConfirmation(booking.id),
      );
      expect(find.text("Couldn't load this booking"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tapVisible(tester, find.text('View my bookings'));
      expect(find.byType(NavigationBar), findsOneWidget, reason: 'back in the Trips tab');
    });

    testWidgets('booking details link back to the destination', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final booking = bookings.seed(userId: testUser.id);
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.booking(booking.id));
      await tapVisible(tester, find.text('View destination'));
      expect(find.text('Best time to visit'), findsOneWidget);
    });
  });

  group('Destination gallery', () {
    testWidgets('a photo opens full screen with a position label, and closes', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.destination('id-cairo'));
      final firstPhoto = find.bySemanticsLabel('Photo 1 of 2');
      await tester.scrollUntilVisible(firstPhoto, 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(firstPhoto);
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewer), findsOneWidget);
      expect(find.text('Photo 1 of 2'), findsOneWidget);
      expect(find.byTooltip('Previous page'), findsNothing, reason: 'already at the first photo');
      // Directional icons mirror themselves in RTL; never swap them by hand.
      expect(Icons.chevron_right.matchTextDirection, isTrue);
      expect(
          find.descendant(of: find.byTooltip('Next page'), matching: find.byIcon(Icons.chevron_right)), findsOneWidget);

      // Buttons work where dragging doesn't (mouse on the web).
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('Photo 2 of 2'), findsOneWidget);
      expect(find.byTooltip('Next page'), findsNothing);
      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();
      expect(find.text('Photo 1 of 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewer), findsNothing);
    });
  });

  group('Large text (200%)', () {
    // Any RenderFlex overflow is reported as a test failure.
    for (final (name, location) in [
      ('Home', AppRoutes.home),
      ('Explore', AppRoutes.explore),
      ('Trips', AppRoutes.bookings),
      ('Profile', AppRoutes.account),
      ('Settings', AppRoutes.settings),
      ('Destination', AppRoutes.destination('id-cairo')),
      ('Booking form', AppRoutes.book('id-cairo')),
      ('Booking details', AppRoutes.booking('bk-1')),
      ('Saved', AppRoutes.favorites),
      ('Notifications', AppRoutes.notifications),
      ('Edit profile', AppRoutes.editProfile),
    ]) {
      for (final lang in ['en', 'ar']) {
        testWidgets('$name lays out without overflow ($lang)', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final bookings = FakeBookingRepository(currentUserId: () => testUser.id)
            ..seed(userId: testUser.id, travelDate: serverToday().add(const Duration(days: 9)));
          await pumpApp(
            tester,
            repo: signedIn(),
            bookings: bookings,
            initialLocation: location,
            prefs: {'onboarding.completed': true, 'settings.locale': lang},
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Wide windows', () {
    testWidgets('tabs move to a side rail on desktop-width windows', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, repo: signedIn());

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Trips')));
      await tester.pumpAndSettle();
      expect(find.text('My bookings'), findsOneWidget);
    });
  });
}
