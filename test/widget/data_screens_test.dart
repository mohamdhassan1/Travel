import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_data_repositories.dart';
import '../helpers/pump_app.dart';

void main() {
  const signedIn = FakeAuthRepository.new;
  Finder inNavBar(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

  group('Explore (catalog)', () {
    testWidgets('lists destinations from the catalog repository', (tester) async {
      await pumpApp(tester, repo: signedIn(signedInAs: testUser), initialLocation: AppRoutes.explore);

      expect(find.text('Explore'), findsWidgets); // title + tab label
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('From \$180'), findsOneWidget);
      expect(find.text('Featured'), findsWidgets);
      expect(find.text('2 destinations'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Kyoto'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text('From \$720'), findsOneWidget);
    });

    testWidgets('the old /destinations path opens Explore', (tester) async {
      await pumpApp(tester, repo: signedIn(signedInAs: testUser), initialLocation: AppRoutes.destinations);
      expect(find.text('Destination, country or experience'), findsOneWidget);
    });

    testWidgets('shows a friendly error and recovers on retry', (tester) async {
      final catalog = FakeCatalogRepository()..nextFailure = const AppFailure(FailureType.network);
      await pumpApp(tester, repo: signedIn(signedInAs: testUser), catalog: catalog, initialLocation: AppRoutes.explore);

      expect(find.text("Couldn't load destinations"), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.textContaining('PGRST'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsOneWidget);
    });

    testWidgets('shows an empty state for an empty catalog', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(signedInAs: testUser),
        catalog: FakeCatalogRepository(destinations: []),
        initialLocation: AppRoutes.explore,
      );
      expect(find.text('No destinations yet'), findsOneWidget);
    });

    testWidgets('renders Arabic content right-to-left', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(signedInAs: testUser),
        prefs: {'onboarding.completed': true, 'settings.locale': 'ar'},
        initialLocation: AppRoutes.explore,
      );
      expect(inNavBar('استكشف'), findsOneWidget);
      expect(find.text('القاهرة'), findsWidgets);
      expect(Directionality.of(tester.element(find.text('القاهرة').first)), TextDirection.rtl);
    });

    testWidgets('requires sign-in', (tester) async {
      await pumpApp(tester, initialLocation: AppRoutes.explore);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets('shows the name stored in the profiles table', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(signedInAs: testUser),
        profile: FakeProfileRepository(profile: const UserProfile(id: 'user-1', fullName: 'Sara A. (from DB)')),
        initialLocation: AppRoutes.account,
      );
      expect(find.text('Sara A. (from DB)'), findsOneWidget);
    });

    testWidgets('reports a profile load failure with retry, keeping auth data visible', (tester) async {
      final profiles = FakeProfileRepository()..nextFailure = const AppFailure(FailureType.permissionDenied);
      await pumpApp(tester,
          repo: signedIn(signedInAs: testUser), profile: profiles, initialLocation: AppRoutes.account);

      expect(find.textContaining("We couldn't load your profile details."), findsOneWidget);
      expect(find.text('traveller@example.com'), findsOneWidget);

      await tester.tap(find.text('Try again').first);
      await tester.pumpAndSettle();
      expect(find.textContaining("We couldn't load your profile details."), findsNothing);
    });
  });

  group('Home', () {
    testWidgets('greets the user by their profile name and links into Explore', (tester) async {
      await pumpApp(
        tester,
        repo: signedIn(signedInAs: testUser),
        profile: FakeProfileRepository(profile: const UserProfile(id: 'user-1', fullName: 'Mona Kamal')),
      );
      expect(find.textContaining(', Mona'), findsOneWidget);
      expect(find.text('Where to next?'), findsOneWidget);

      await tester.tap(find.text('See all').first);
      await tester.pumpAndSettle();
      expect(find.text('Destination, country or experience'), findsOneWidget);
    });
  });
}
