import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(signedInAs: testUser);
  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: scrollable());
    await tester.pumpAndSettle();
  }

  /// Opens the booking form for Cairo's first package from its details page.
  Future<void> openBookingForm(WidgetTester tester) async {
    await scrollTo(tester, find.text('Book this package').first);
    await tester.tap(find.text('Book this package').first);
    await tester.pumpAndSettle();
    expect(find.text('Book your trip'), findsOneWidget);
  }

  /// Fills the details step with valid input and moves to review.
  Future<void> fillAndReview(WidgetTester tester, {int extraTravelers = 1}) async {
    await scrollTo(tester, find.text('Choose a date'));
    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // earliest bookable date (tomorrow, server time)
    await tester.pumpAndSettle();

    for (var i = 0; i < extraTravelers; i++) {
      await tester.tap(find.byTooltip('More travellers'));
      await tester.pump();
    }

    await scrollTo(tester, find.widgetWithText(TextFormField, 'Phone number'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), '+20 100 000 0000');
    await scrollTo(tester, find.text('Review booking'));
    await tester.tap(find.text('Review booking'));
    await tester.pumpAndSettle();
    expect(find.text('Review your booking'), findsOneWidget);
  }

  group('Booking flow', () {
    testWidgets('details → package → form → review → confirm → confirmation → My bookings', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.destination('id-cairo'));

      await openBookingForm(tester);
      // Contact name prefilled from the real account name.
      expect(find.widgetWithText(TextFormField, 'Sara Ali'), findsOneWidget);

      await fillAndReview(tester);
      expect(find.text('2 travellers'), findsWidgets);
      expect(find.text('\$840'), findsOneWidget, reason: '420 × 2 from the selected package');
      expect(find.textContaining('No payment is taken'), findsOneWidget);
      expect(bookings.calls.where((c) => c == 'create'), isEmpty, reason: 'nothing is sent before confirming');

      await scrollTo(tester, find.text('Confirm booking'));
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(find.text('Booking confirmed'), findsOneWidget);
      final stored = bookings.storedBooking('bk-1');
      expect(find.text(stored.reference), findsOneWidget, reason: 'reference read back from the backend');
      expect(find.text('\$840'), findsOneWidget);

      await scrollTo(tester, find.text('View my bookings'));
      await tester.tap(find.text('View my bookings'));
      await tester.pumpAndSettle();
      expect(find.text('My bookings'), findsOneWidget);
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);

      // Not a dead end: it's the Trips tab, with the bottom navigation.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Home')));
      await tester.pumpAndSettle();
      expect(find.text('Your next trip'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget, reason: 'the new booking is the next trip');
    });

    testWidgets('validation blocks review until package, date and contact details are valid', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.book('id-cairo'));

      await scrollTo(tester, find.text('Review booking'));
      await tester.tap(find.text('Review booking'));
      await tester.pumpAndSettle();

      expect(find.text('Review your booking'), findsNothing);
      await scrollTo(tester, find.text('This field is required'));
      expect(find.text('This field is required'), findsOneWidget, reason: 'phone is required');

      await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), 'call me');
      await scrollTo(tester, find.text('Review booking'));
      await tester.tap(find.text('Review booking'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.textContaining('Enter a valid phone number'));
      await tester.drag(scrollable(), const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.text('Choose a package'), findsWidgets);
      expect(find.text('Choose a travel date'), findsOneWidget);
      expect(bookings.calls.where((c) => c == 'create'), isEmpty);
    });

    testWidgets('a backend rejection stays on review with a clear message', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)
        ..nextCreateFailure = const AppFailure(FailureType.packageUnavailable);
      await pumpApp(
        tester,
        repo: signedIn(),
        bookings: bookings,
        initialLocation: AppRoutes.book('id-cairo', packageId: 'pkg-1'),
      );

      await fillAndReview(tester);
      await scrollTo(tester, find.text('Confirm booking'));
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(find.text('Booking confirmed'), findsNothing);
      expect(find.textContaining('This package is no longer available'), findsOneWidget);
      expect(find.text('Review your booking'), findsOneWidget);
      expect(bookings.countFor(testUser.id), 0);
    });

    testWidgets('double tap on Confirm creates exactly one booking', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)..createGate = Completer<void>();
      await pumpApp(
        tester,
        repo: signedIn(),
        bookings: bookings,
        initialLocation: AppRoutes.book('id-cairo', packageId: 'pkg-1'),
      );

      await fillAndReview(tester, extraTravelers: 0);
      await scrollTo(tester, find.text('Confirm booking'));
      await tester.tap(find.text('Confirm booking'));
      await tester.pump();
      await tester.tap(find.text('Confirm booking'), warnIfMissed: false);
      await tester.pump();
      bookings.createGate!.complete();
      await tester.pumpAndSettle();

      expect(bookings.calls.where((c) => c == 'create'), hasLength(1));
      expect(bookings.countFor(testUser.id), 1);
      expect(find.text('Booking confirmed'), findsOneWidget);
    });

    testWidgets('an unknown destination shows not-found instead of a form', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.book('no-such-destination'));
      expect(find.text('Destination not found'), findsOneWidget);
    });
  });

  group('My bookings', () {
    testWidgets('empty state offers to browse', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.bookings);
      expect(find.text('No bookings yet'), findsOneWidget);
      await tester.tap(find.text('Browse destinations'));
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget);
    });

    testWidgets('error then retry', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)
        ..nextLoadFailure = const AppFailure(FailureType.network);
      bookings.seed(userId: testUser.id);
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.bookings);

      expect(find.text("Couldn't load your bookings"), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget);
    });

    testWidgets('Upcoming / Past / Cancelled filters use dates and the database status', (tester) async {
      final today = serverToday();
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      bookings.seed(userId: testUser.id, travelDate: today.add(const Duration(days: 20)));
      bookings.seed(userId: testUser.id, travelDate: today.subtract(const Duration(days: 20)));
      bookings.seed(userId: testUser.id, status: BookingStatus.cancelled);
      bookings.seed(userId: 'user-2'); // someone else's — never shown
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.bookings);

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Past trip'), findsNothing);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Past trip'), findsOneWidget);
      expect(find.text('Confirmed'), findsNothing);

      await tester.tap(find.text('Cancelled').first);
      await tester.pumpAndSettle();
      expect(find.text('Cancelled'), findsNWidgets(2)); // segment + status chip
    });

    testWidgets('cancel from details: confirm dialog, backend call, status updated, list refreshed', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id);
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.bookings);

      await tester.tap(find.text('Cairo'));
      await tester.pumpAndSettle();
      expect(find.text('Booking details'), findsOneWidget);

      await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this booking?'), findsOneWidget);

      // "Keep booking" does nothing.
      await tester.tap(find.text('Keep booking'));
      await tester.pumpAndSettle();
      expect(bookings.calls.where((c) => c.startsWith('cancel')), isEmpty);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();

      expect(find.text('Booking cancelled'), findsOneWidget);
      expect(bookings.storedBooking(mine.id).isCancelled, isTrue);
      expect(find.widgetWithText(OutlinedButton, 'Cancel booking'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelled').first);
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget, reason: 'list reloaded from the backend');
    });

    testWidgets('a failed cancellation keeps the booking confirmed', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)
        ..nextCancelFailure = const AppFailure(FailureType.network);
      final mine = bookings.seed(userId: testUser.id);
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.booking(mine.id));

      await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't cancel the booking."), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(bookings.storedBooking(mine.id).isCancelled, isFalse);
    });

    testWidgets('another account\'s booking id shows not-found', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final theirs = bookings.seed(userId: 'user-2');
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.booking(theirs.id));
      expect(find.text('Booking not found'), findsOneWidget);
      await pumpApp(tester,
          repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.bookingConfirmation(theirs.id));
      expect(find.text('Booking confirmed'), findsNothing);
    });

    testWidgets('signing out from My bookings leaves no booking data on screen', (tester) async {
      final auth = signedIn();
      final bookings = FakeBookingRepository(currentUserId: () => auth.currentUser?.id);
      bookings.seed(userId: testUser.id);
      await pumpApp(tester, repo: auth, bookings: bookings, initialLocation: AppRoutes.bookings);
      expect(find.text('Cairo'), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Cairo'), findsNothing);
    });
  });

  group('Route protection', () {
    for (final route in [AppRoutes.bookings, AppRoutes.book('id-cairo'), AppRoutes.booking('bk-1')]) {
      testWidgets('$route requires sign-in', (tester) async {
        await pumpApp(tester, initialLocation: route);
        expect(find.text('Welcome back'), findsOneWidget);
      });
    }
  });

  group('Arabic', () {
    testWidgets('My bookings and details render right-to-left with database values', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id);
      final mine = bookings.seed(userId: testUser.id);
      await pumpApp(
        tester,
        repo: signedIn(),
        bookings: bookings,
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.bookings,
      );

      expect(find.text('حجوزاتي'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('حجوزاتي'))), TextDirection.rtl);
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.text('مؤكَّد'), findsOneWidget);
      expect(find.text('مسافران'), findsOneWidget, reason: 'Arabic dual for 2 travellers');

      await tester.tap(find.text('القاهرة'));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل الحجز'), findsOneWidget);
      expect(find.text(mine.reference), findsOneWidget);
    });

    testWidgets('booking form and review in Arabic', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(),
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.book('id-cairo', packageId: 'pkg-1'),
      );
      expect(find.text('احجز رحلتك'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('احجز رحلتك'))), TextDirection.rtl);
      await scrollTo(tester, find.text('مراجعة الحجز'));
      await tester.tap(find.text('مراجعة الحجز'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('هذا الحقل مطلوب'));
      expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    });
  });
}
