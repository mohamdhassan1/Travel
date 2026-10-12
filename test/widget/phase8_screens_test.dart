import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/core/theme/app_colors.dart';
import 'package:rahala/core/theme/app_theme.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/models/catalog_models.dart';
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_data_repositories.dart';
import '../helpers/fake_phase8.dart';
import '../helpers/pump_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(signedInAs: testUser);
  Finder tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  group('Bottom navigation', () {
    testWidgets('five tabs; each keeps its place; details cover the bar', (tester) async {
      await pumpApp(tester, repo: signedIn());
      for (final label in ['Home', 'Explore', 'Trips', 'Saved', 'Profile']) {
        expect(tab(label), findsOneWidget);
      }
      await tester.tap(tab('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget);

      await tester.tap(find.text('Kyoto'));
      await tester.pumpAndSettle();
      expect(find.text('Best time to visit'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing, reason: 'full-screen details');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(tab('Trips'));
      await tester.pumpAndSettle();
      expect(find.text('My bookings'), findsOneWidget);
      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Where to next?'), findsOneWidget);
    });

    testWidgets('Arabic: labels translated and the bar is right-to-left', (tester) async {
      await pumpApp(tester, repo: signedIn(), prefs: {'onboarding.completed': true, 'settings.locale': 'ar'});
      expect(tab('الرئيسية'), findsOneWidget);
      expect(tab('حسابي'), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(NavigationBar))), TextDirection.rtl);
      // Home is the start (right-most) item in RTL.
      final home = tester.getCenter(tab('الرئيسية'));
      final profile = tester.getCenter(tab('حسابي'));
      expect(home.dx, greaterThan(profile.dx));
    });
  });

  group('Home', () {
    testWidgets('next trip with a countdown from the user\'s real booking', (tester) async {
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)
        ..seed(userId: testUser.id, travelDate: serverToday().add(const Duration(days: 12)))
        ..seed(userId: testUser.id, travelDate: serverToday().add(const Duration(days: 40)))
        ..seed(userId: 'user-2', travelDate: serverToday().add(const Duration(days: 2)));
      await pumpApp(tester, repo: signedIn(), bookings: bookings);
      expect(find.text('In 12 days'), findsOneWidget, reason: 'soonest of my own trips');
      expect(find.text('In 2 days'), findsNothing, reason: 'never another user\'s booking');
    });

    testWidgets('no trips: an honest empty card that leads to Explore', (tester) async {
      await pumpApp(tester, repo: signedIn());
      expect(find.text('No upcoming trips'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget);
    });

    testWidgets('categories come from the catalog and open Explore pre-filtered', (tester) async {
      await pumpApp(tester, repo: signedIn());
      await scrollTo(tester, find.text('Beaches'));
      await tester.tap(find.text('Beaches'));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Beaches'));
      expect(chip.selected, isTrue);
      expect(find.text('No matching destinations'), findsOneWidget, reason: 'the fake catalog has no beaches');
    });

    testWidgets('featured section uses the catalog flag, no invented popularity', (tester) async {
      await pumpApp(tester, repo: signedIn());
      await scrollTo(tester, find.text('Featured destinations'));
      expect(find.text('Hand-picked from the Rahala catalog'), findsOneWidget);
      expect(find.textContaining('popular', findRichText: true), findsNothing);
      expect(find.textContaining('rating', findRichText: true), findsNothing);
    });

    testWidgets('a catalog failure is explained and retried without hiding trips', (tester) async {
      final catalog = FakeCatalogRepository()..nextFailure = const AppFailure(FailureType.network);
      await pumpApp(tester, repo: signedIn(), catalog: catalog);
      expect(find.text('Your next trip'), findsOneWidget);
      await scrollTo(tester, find.textContaining("Couldn't load destinations."));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Featured destinations'));
    });

    testWidgets('recently viewed appears after opening a destination', (tester) async {
      await pumpApp(tester, repo: signedIn());
      expect(find.text('Recently viewed'), findsNothing);
      await tester.tap(tab('Explore'));
      await tester.pumpAndSettle();
      // The fake ids aren't UUIDs, so recording is skipped: nothing is invented.
      await tester.tap(find.text('Kyoto'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Recently viewed'), findsNothing);
    });
  });

  group('Recently viewed', () {
    testWidgets('a real destination opened is listed on Home, newest first', (tester) async {
      const petraId = '7f1c2d3e-4b5a-4c6d-8e7f-9a0b1c2d3e4f';
      final petra = DestinationSummary.fromJson(
          {...destinationRow(slug: 'petra', nameEn: 'Petra', featured: false), 'id': petraId});
      final catalog = FakeCatalogRepository(
        destinations: [...sampleDestinations, petra],
        details: {
          ...sampleDetails,
          petraId:
              DestinationDetails.fromJson({...destinationDetailsRow(slug: 'petra', nameEn: 'Petra'), 'id': petraId}),
        },
      );
      await pumpApp(tester, repo: signedIn(), catalog: catalog, initialLocation: AppRoutes.destination(petraId));
      expect(find.text('Best time to visit'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      // Opened as a deep link, Back lands in Explore; go Home from the tab bar.
      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Recently viewed'));
      expect(find.text('Petra'), findsWidgets);
    });
  });

  group('Explore', () {
    Future<void> openExplore(WidgetTester tester, {String locale = 'en'}) =>
        pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.explore, prefs: {
          'onboarding.completed': true,
          'settings.locale': locale,
        });

    testWidgets('search narrows results (after the debounce) and clears', (tester) async {
      await openExplore(tester);
      await tester.enterText(find.byType(TextField), 'kyo');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('1 destination'), findsOneWidget);
      expect(find.text('Cairo'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('2 destinations'), findsOneWidget);
    });

    testWidgets('Arabic text matches in the English UI, despite spelling variants', (tester) async {
      await openExplore(tester);
      await tester.enterText(find.byType(TextField), 'القاهره');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget);
    });

    testWidgets('no results: a clear message and a reset action', (tester) async {
      await openExplore(tester);
      await tester.enterText(find.byType(TextField), 'atlantis');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No matching destinations'), findsOneWidget);
      expect(find.textContaining('atlantis'), findsWidgets);
      await tester.tap(find.text('Clear search & filters'));
      await tester.pumpAndSettle();
      expect(find.text('2 destinations'), findsOneWidget);
    });

    testWidgets('filters sheet: price from real data; applied count shown', (tester) async {
      await openExplore(tester);
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Starting price per person'), findsOneWidget);
      expect(find.textContaining('sample catalog prices'), findsOneWidget);
      // Real range from the catalog (from $180 and $720) → slider $150–$750.
      // At its minimum ($150) no destination's starting price fits.
      await tester.drag(find.byType(Slider), const Offset(-1000, 0));
      await tester.pump();
      expect(find.text(r'Up to $150'), findsOneWidget);
      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();
      expect(find.text('No matching destinations'), findsOneWidget);
      expect(find.text('No destination fits these filters. Try widening them.'), findsOneWidget);
      expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);

      // Short trips (1–3 days) at any price: both fake destinations (2–4 days).
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.tap(find.text('Short break (1–3 days)'));
      await tester.pump();
      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();
      expect(find.text('2 destinations'), findsOneWidget);
    });

    testWidgets('Arabic, right-to-left', (tester) async {
      await openExplore(tester, locale: 'ar');
      expect(find.text('وجهة أو دولة أو تجربة'), findsOneWidget);
      expect(find.text('وجهتان'), findsOneWidget, reason: 'Arabic dual');
      expect(Directionality.of(tester.element(find.byType(TextField))), TextDirection.rtl);
    });
  });

  group('Profile', () {
    testWidgets('statistics and level come only from the user\'s bookings', (tester) async {
      final today = serverToday();
      final bookings = FakeBookingRepository(currentUserId: () => testUser.id)
        ..seed(userId: testUser.id, travelDate: today.subtract(const Duration(days: 30)))
        ..seed(userId: testUser.id, travelDate: today.add(const Duration(days: 30)))
        ..seed(userId: testUser.id, travelDate: today.add(const Duration(days: 60)), status: BookingStatus.cancelled)
        ..seed(userId: 'user-2', travelDate: today.subtract(const Duration(days: 90)));
      await pumpApp(tester, repo: signedIn(), bookings: bookings, initialLocation: AppRoutes.account);

      expect(find.text('Explorer'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips taken: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Upcoming: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Countries visited: 1'), findsOneWidget);
      expect(find.text('Based on your 3 bookings · 1 cancelled'), findsOneWidget);
      expect(find.text('2 more completed trips, 1 more country to become Voyager.'), findsOneWidget);

      await tester.tap(find.byTooltip('How levels work'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.textContaining("isn't a rating from other people"), 100,
          scrollable: find.byType(Scrollable).last);
      expect(find.textContaining("isn't a rating from other people"), findsOneWidget);
    });

    testWidgets('new user: no fake numbers', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.account);
      expect(find.text('New traveler'), findsOneWidget);
      expect(find.text('1 more completed trip to become Explorer.'), findsOneWidget,
          reason: 'no redundant country clause');
      expect(find.textContaining('No bookings yet'), findsOneWidget);
    });

    testWidgets('edit profile: validation, save, and the new name everywhere', (tester) async {
      final profiles = FakeProfileRepository();
      await pumpApp(tester, repo: signedIn(), profile: profiles, initialLocation: AppRoutes.editProfile);

      final save = find.widgetWithText(FilledButton, 'Save changes');
      expect(tester.widget<FilledButton>(save).onPressed, isNull, reason: 'nothing changed yet');
      expect(find.text('traveller@example.com'), findsOneWidget);
      expect(find.text("Your sign-in email can't be changed here."), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2), reason: 'no password field');

      await tester.enterText(find.widgetWithText(TextFormField, 'Phone (optional)'), 'call me');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a valid phone number'), findsOneWidget);
      expect(profiles.calls.where((c) => c.startsWith('update')), isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'Phone (optional)'), '+20 111 222 3333');
      await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Sara Ahmed');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.text('Profile updated.'), findsOneWidget);
      expect(profiles.profileOf('user-1').fullName, 'Sara Ahmed');
      expect(profiles.profileOf('user-1').phone, '+20 111 222 3333');
    });

    testWidgets('leaving with unsaved edits asks first', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.account);
      await tester.ensureVisible(find.text('Edit profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Changed');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Changed'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Sara Ali'), findsOneWidget, reason: 'nothing was saved');
    });

    testWidgets('photo: pick → upload → shown; remove; picker cancel does nothing', (tester) async {
      final profiles = FakeProfileRepository();
      final picker = FakePhotoPicker(next: FakePhotoPicker.jpeg());
      await pumpApp(tester,
          repo: signedIn(), profile: profiles, photoPicker: picker, initialLocation: AppRoutes.account);

      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(profiles.profileOf('user-1').avatarPath, startsWith('user-1/'));
      expect(find.text('Profile photo updated.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5)); // let the snack bar go
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(profiles.profileOf('user-1').avatarPath, isNull);

      picker.next = null; // user cancels the picker
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(profiles.calls.where((c) => c.startsWith('upload')), hasLength(1));
    });

    testWidgets('account switch: the next user never sees the previous name', (tester) async {
      final auth = signedIn();
      final profiles = FakeProfileRepository(currentUserId: () => auth.currentUser?.id, profiles: {
        'user-1': const UserProfile(id: 'user-1', fullName: 'Sara Ali'),
        'user-2': const UserProfile(id: 'user-2', fullName: 'Omar Nabil'),
      });
      await pumpApp(tester, repo: auth, profile: profiles, initialLocation: AppRoutes.account);
      expect(find.text('Sara Ali'), findsOneWidget);
      auth.switchTo(const AppUser(id: 'user-2', email: 'omar@example.com', fullName: 'Omar', emailConfirmed: true));
      await tester.pumpAndSettle();
      await tester.tap(tab('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Omar Nabil'), findsOneWidget);
      expect(find.text('Sara Ali'), findsNothing);
    });
  });

  group('Destination details extras', () {
    testWidgets('live weather card with its source', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.destination('id-cairo'));
      await scrollTo(tester, find.text('Weather now'));
      expect(find.text('24°C'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.textContaining('Open-Meteo.com'), findsOneWidget);
    });

    testWidgets('a weather failure never blocks the page', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(),
        weather: FakeWeatherRepository(failure: const AppFailure(FailureType.network)),
        initialLocation: AppRoutes.destination('id-cairo'),
      );
      await scrollTo(tester, find.text('Weather is unavailable right now.'));
      expect(find.text('Best time to visit'), findsOneWidget);
    });

    testWidgets('share sends the name and in-app link', (tester) async {
      final share = FakeShareService();
      await pumpApp(tester, repo: signedIn(), share: share, initialLocation: AppRoutes.destination('id-cairo'));
      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(share.shared.single, contains('Cairo, Egypt'));
      expect(share.shared.single, contains('rahala://rahala.app/destinations/id-cairo'));
    });

    testWidgets('sharing unavailable says so', (tester) async {
      await pumpApp(tester,
          repo: signedIn(),
          share: FakeShareService(available: false),
          initialLocation: AppRoutes.destination('id-cairo'));
      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(find.text("Sharing isn't available on this device."), findsOneWidget);
    });
  });

  group('Theme', () {
    test('raised surfaces are lighter than the page in both themes', () {
      final light = AppTheme.light(const Locale('en'), useGoogleFonts: false);
      final dark = AppTheme.dark(const Locale('en'), useGoogleFonts: false);
      expect(light.cardTheme.color, AppColors.lightScheme.surfaceContainerLowest);
      expect(
        dark.cardTheme.color!.computeLuminance(),
        greaterThan(AppColors.darkScheme.surface.computeLuminance()),
        reason: 'dark cards must not be darker than the background',
      );
      expect(dark.navigationBarTheme.backgroundColor!.computeLuminance(),
          greaterThan(AppColors.darkScheme.surface.computeLuminance()));
      expect(
          dark.dialogTheme.backgroundColor!.computeLuminance(), greaterThan(dark.cardTheme.color!.computeLuminance()));
    });

    testWidgets('Home renders in dark mode with themed surfaces', (tester) async {
      await pumpApp(tester, repo: signedIn(), prefs: {
        'onboarding.completed': true,
        'settings.locale': 'en',
        'settings.theme_mode': 'dark',
      });
      final context = tester.element(find.text('Where to next?'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });
}
