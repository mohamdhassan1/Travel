import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_data_repositories.dart';
import '../helpers/pump_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(signedInAs: testUser);
  Finder scrollable() => find.byType(Scrollable).first;
  Finder tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

  group('Destination details', () {
    testWidgets('Browse → details shows database content and packages → back', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.explore);

      await tester.tap(find.text('Cairo'));
      await tester.pumpAndSettle();

      expect(find.text('Cairo'), findsWidgets);
      expect(find.text('Best time to visit'), findsOneWidget);
      expect(find.text('October – April'), findsOneWidget);
      expect(find.text('30.0444, 31.2357'), findsOneWidget);
      expect(find.textContaining('Giza plateau'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Pyramids & Old Cairo Discovery'), 200, scrollable: scrollable());
      expect(find.text('\$420'), findsOneWidget);
      expect(find.text('4 days'), findsOneWidget);
      expect(find.text('Up to 8 travellers'), findsWidgets);
      expect(find.text("What's included"), findsWidgets);
      await tester.scrollUntilVisible(find.textContaining('Photos: Wikimedia Commons'), 200, scrollable: scrollable());

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget, reason: 'back in Explore');
    });

    testWidgets('a destination without packages says so honestly', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.destination('id-kyoto'));
      await tester.scrollUntilVisible(find.text('No packages are available for this destination right now.'), 200,
          scrollable: scrollable());
    });

    testWidgets('an unknown id shows a not-found state, not a crash', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.destination('no-such-destination'));

      expect(find.text('Destination not found'), findsOneWidget);
      await tester.tap(find.text('Back to destinations'));
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget);
    });

    testWidgets('a load failure shows a friendly error and retries', (tester) async {
      final catalog = FakeCatalogRepository()..nextDetailsFailure = const AppFailure(FailureType.network);
      await pumpApp(tester, repo: signedIn(), catalog: catalog, initialLocation: AppRoutes.destination('id-cairo'));

      expect(find.text("Couldn't load this destination"), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Best time to visit'), findsOneWidget);
    });

    testWidgets('a packages failure keeps the destination visible and retries packages', (tester) async {
      final catalog = FakeCatalogRepository()..nextPackagesFailure = const AppFailure(FailureType.timeout);
      await pumpApp(tester, repo: signedIn(), catalog: catalog, initialLocation: AppRoutes.destination('id-cairo'));

      await tester.scrollUntilVisible(find.textContaining("Couldn't load packages."), 200, scrollable: scrollable());
      expect(find.text('Best time to visit'), findsOneWidget);
      await tester.ensureVisible(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Cairo Weekend Escape'), 200, scrollable: scrollable());
    });

    testWidgets('renders in Arabic, right-to-left', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(),
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.destination('id-cairo'),
      );

      expect(find.text('أفضل وقت للزيارة'), findsOneWidget);
      expect(find.text('أكتوبر – أبريل'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('أفضل وقت للزيارة'))), TextDirection.rtl);

      await tester.scrollUntilVisible(find.text('اكتشاف الأهرامات والقاهرة القديمة'), 200, scrollable: scrollable());
      expect(find.text('الباقات'), findsOneWidget);
      expect(find.text('ما تشمله الباقة'), findsWidgets);
      expect(find.textContaining('مسافر'), findsWidgets);
    });
  });

  group('Favourites', () {
    testWidgets('Home → Explore → Cairo → favourite → Saved → remove → undo', (tester) async {
      final favorites = FakeFavoritesRepository();
      await pumpApp(tester, repo: signedIn(), favorites: favorites);

      await tester.tap(tab('Explore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cairo'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add to favourites'));
      await tester.pumpAndSettle();
      expect(find.text('Saved to favourites'), findsOneWidget);
      expect(find.byTooltip('Remove from favourites'), findsOneWidget);
      expect(favorites.idsFor(testUser.id), ['id-cairo'], reason: 'persisted through the repository');

      // Back to Explore (the heart there reflects the shared state), then Saved.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove from favourites'), findsOneWidget);
      await tester.tap(tab('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from favourites'));
      await tester.pumpAndSettle();
      expect(find.text('No favourites yet'), findsOneWidget);
      expect(find.text('Removed from favourites'), findsOneWidget);
      expect(favorites.idsFor(testUser.id), isEmpty);

      // Undo restores it on the server and in the list.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget);
      expect(favorites.idsFor(testUser.id), ['id-cairo']);
    });

    testWidgets('a failed save is rolled back and explained', (tester) async {
      final favorites = FakeFavoritesRepository()..nextWriteFailure = const AppFailure(FailureType.network);
      await pumpApp(tester, repo: signedIn(), favorites: favorites, initialLocation: AppRoutes.destination('id-cairo'));

      await tester.tap(find.byTooltip('Add to favourites'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't save to favourites."), findsOneWidget);
      expect(find.text('Saved to favourites'), findsNothing);
      expect(find.byTooltip('Add to favourites'), findsOneWidget, reason: 'heart rolled back');
      expect(favorites.idsFor(testUser.id), isEmpty);
    });

    testWidgets('empty state offers to browse', (tester) async {
      await pumpApp(tester, repo: signedIn(), initialLocation: AppRoutes.favorites);

      expect(find.text('No favourites yet'), findsOneWidget);
      await tester.tap(find.text('Browse destinations'));
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget);
    });

    testWidgets('Favourites → details → back returns to Favourites', (tester) async {
      final favorites = FakeFavoritesRepository(initial: {
        testUser.id: ['id-kyoto'],
      });
      await pumpApp(tester, repo: signedIn(), favorites: favorites, initialLocation: AppRoutes.favorites);

      await tester.tap(find.text('Kyoto'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove from favourites'), findsOneWidget, reason: 'state shared with details');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('Kyoto'), findsOneWidget);
    });

    testWidgets('a load failure shows an error with retry', (tester) async {
      final favorites = FakeFavoritesRepository()..nextLoadFailure = const AppFailure(FailureType.server);
      await pumpApp(tester, repo: signedIn(), favorites: favorites, initialLocation: AppRoutes.favorites);

      expect(find.text("Couldn't load your favourites"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No favourites yet'), findsOneWidget);
    });

    testWidgets('signing out clears a pending "Undo" snack bar (found in manual testing)', (tester) async {
      final favorites = FakeFavoritesRepository(initial: {
        testUser.id: ['id-kyoto'],
      });
      final auth = signedIn();
      await pumpApp(tester, repo: auth, favorites: favorites, initialLocation: AppRoutes.favorites);

      await tester.tap(find.byTooltip('Remove from favourites'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
      expect(find.text('Removed from favourites'), findsNothing);
    });

    testWidgets('requires sign-in', (tester) async {
      await pumpApp(tester, initialLocation: AppRoutes.favorites);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Arabic favourites screen is right-to-left', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(),
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.favorites,
      );
      expect(find.text('لا توجد وجهات مفضلة بعد'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('المفضلة'))), TextDirection.rtl);
    });
  });
}
