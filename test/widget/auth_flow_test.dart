import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/auth_repository.dart';
import 'package:rahala/routing/app_routes.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('first launch shows onboarding, then login', (tester) async {
    await pumpApp(tester, prefs: {'settings.locale': 'en'});

    expect(find.text('Discover places that move you'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('login validates input before calling the backend', (
    tester,
  ) async {
    final repo = await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsNWidgets(2));
    expect(repo.calls, isEmpty);

    await tester.enterText(field('Email'), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('invalid credentials show an inline error', (tester) async {
    final repo = await pumpApp(tester);
    repo.nextFailure = const AppFailure(FailureType.invalidCredentials);

    await tester.enterText(field('Email'), 'traveller@example.com');
    await tester.enterText(field('Password'), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('unconfirmed email offers to resend the confirmation', (
    tester,
  ) async {
    final repo = await pumpApp(tester);
    repo.nextFailure = const AppFailure(FailureType.emailNotConfirmed);

    await tester.enterText(field('Email'), 'traveller@example.com');
    await tester.enterText(field('Password'), 'travel2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resend confirmation email'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('resend:traveller@example.com'));
    expect(
      find.text('Confirmation email sent. Check your inbox.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'successful sign-in lands on Home with real user data',
    (tester) async {
      await pumpApp(tester);

      await tester.enterText(field('Email'), 'traveller@example.com');
      await tester.enterText(field('Password'), 'travel2026');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Where to next?'), findsOneWidget);
      // Real account data on the Profile tab.
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      expect(find.text('traveller@example.com'), findsOneWidget);
    },
  );

  testWidgets('a protected deep link requires sign-in, then opens', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: AppRoutes.settings);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(field('Email'), 'traveller@example.com');
    await tester.enterText(field('Password'), 'travel2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('restored session skips auth; sign-out returns to login', (
    tester,
  ) async {
    final repo = await pumpApp(
      tester,
      repo: FakeAuthRepository(signedInAs: testUser),
      initialLocation: AppRoutes.account,
    );
    expect(find.text('Sara Ali'), findsOneWidget);

    // The Profile list scrolls; bring Sign out into view like a user would.
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(repo.calls, contains('signOut'));
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sara Ali'), findsNothing);
  });

  testWidgets('an expired session returns to login with a notice', (
    tester,
  ) async {
    final repo = await pumpApp(
      tester,
      repo: FakeAuthRepository(signedInAs: testUser),
    );
    repo.expireSession();
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text("You've been signed out. Please sign in again."),
      findsOneWidget,
    );
  });

  testWidgets(
    'registration with email confirmation shows the check-inbox state',
    (tester) async {
      final repo = await pumpApp(tester, initialLocation: AppRoutes.register);
      repo.signUpOutcome = SignUpOutcome.confirmationRequired;

      await tester.enterText(field('Full name'), 'Sara Ali');
      await tester.enterText(field('Email'), 'new@example.com');
      await tester.enterText(field('Password'), 'travel2026');
      await tester.enterText(field('Confirm password'), 'travel2026');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.calls, contains('signUp:new@example.com'));
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.textContaining('new@example.com'), findsOneWidget);
    },
  );

  testWidgets('register rejects mismatched and weak passwords', (tester) async {
    final repo = await pumpApp(tester, initialLocation: AppRoutes.register);

    await tester.enterText(field('Full name'), 'Sara Ali');
    await tester.enterText(field('Email'), 'new@example.com');
    await tester.enterText(field('Password'), 'password');
    await tester.enterText(field('Confirm password'), 'different1');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('Include at least one letter and one number'),
      findsOneWidget,
    );
    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('unknown routes show the not-found screen', (tester) async {
    await pumpApp(
      tester,
      repo: FakeAuthRepository(signedInAs: testUser),
      initialLocation: '/nowhere',
    );
    expect(find.text('Page not found'), findsOneWidget);
  });
}
