import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/app_preferences.dart';
import 'package:rahala/data/repositories/auth_repository.dart';
import 'package:rahala/logic/auth/auth_form_cubits.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/settings/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  group('SessionCubit', () {
    test('restores an existing session synchronously', () {
      final cubit = SessionCubit(FakeAuthRepository(signedInAs: testUser));
      expect(cubit.state.status, SessionStatus.authenticated);
      expect(cubit.state.user, testUser);
    });

    test('starts unauthenticated without a stored session', () {
      expect(
        SessionCubit(FakeAuthRepository()).state.status,
        SessionStatus.unauthenticated,
      );
    });

    test('follows sign-in', () async {
      final repo = FakeAuthRepository();
      final cubit = SessionCubit(repo);
      await repo.signIn(email: 'a@b.co', password: 'pw');
      await pumpEventQueue();
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user?.email, 'a@b.co');
    });

    test('a user-initiated sign-out is not flagged as unexpected', () async {
      final cubit = SessionCubit(FakeAuthRepository(signedInAs: testUser));
      await cubit.signOut();
      await pumpEventQueue();
      expect(cubit.state.status, SessionStatus.unauthenticated);
      expect(cubit.state.endedUnexpectedly, isFalse);
    });

    test(
      'a server-side session end is flagged and can be acknowledged',
      () async {
        final repo = FakeAuthRepository(signedInAs: testUser);
        final cubit = SessionCubit(repo);
        repo.expireSession();
        await pumpEventQueue();
        expect(cubit.state.endedUnexpectedly, isTrue);
        cubit.acknowledgeSessionEnded();
        expect(cubit.state.endedUnexpectedly, isFalse);
      },
    );

    test('password recovery is tracked until completed', () async {
      final repo = FakeAuthRepository();
      final cubit = SessionCubit(repo);
      repo.emitPasswordRecovery();
      await pumpEventQueue();
      expect(cubit.state.passwordRecovery, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      cubit.completePasswordRecovery();
      expect(cubit.state.passwordRecovery, isFalse);
    });
  });

  group('SettingsCubit', () {
    Future<AppPreferences> prefs([
      Map<String, Object> initial = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initial);
      return AppPreferences(await SharedPreferences.getInstance());
    }

    test('defaults to system theme/locale and no onboarding', () async {
      final cubit = SettingsCubit(await prefs());
      expect(cubit.state.themeMode, ThemeMode.system);
      expect(cubit.state.locale, isNull);
      expect(cubit.state.onboardingCompleted, isFalse);
    });

    test('persists choices across instances', () async {
      final p = await prefs();
      final cubit = SettingsCubit(p);
      await cubit.setLocale(const Locale('ar'));
      await cubit.setThemeMode(ThemeMode.dark);
      await cubit.completeOnboarding();

      final reloaded = SettingsCubit(p);
      expect(reloaded.state.locale, const Locale('ar'));
      expect(reloaded.state.themeMode, ThemeMode.dark);
      expect(reloaded.state.onboardingCompleted, isTrue);

      await reloaded.setLocale(null);
      expect(SettingsCubit(p).state.locale, isNull);
    });
  });

  group('auth form cubits', () {
    late FakeAuthRepository repo;
    setUp(() => repo = FakeAuthRepository());

    blocTest<LoginCubit, SubmitState<void>>(
      'emits submitting then success',
      build: () => LoginCubit(repo),
      act: (c) => c.submit(email: 'a@b.co', password: 'pw'),
      expect: () => [
        const SubmitState<void>(status: SubmitStatus.submitting),
        const SubmitState<void>(status: SubmitStatus.success),
      ],
    );

    blocTest<LoginCubit, SubmitState<void>>(
      'emits the mapped failure',
      build: () => LoginCubit(
        repo..nextFailure = const AppFailure(FailureType.invalidCredentials),
      ),
      act: (c) => c.submit(email: 'a@b.co', password: 'bad'),
      expect: () => [
        const SubmitState<void>(status: SubmitStatus.submitting),
        const SubmitState<void>(
          status: SubmitStatus.failure,
          failure: AppFailure(FailureType.invalidCredentials),
        ),
      ],
    );

    blocTest<LoginCubit, SubmitState<void>>(
      'ignores a second submit while one is in flight',
      build: () => LoginCubit(repo),
      act: (c) {
        c.submit(email: 'a@b.co', password: 'pw');
        c.submit(email: 'a@b.co', password: 'pw');
      },
      verify: (_) => expect(repo.calls.where((c) => c.startsWith('signIn')), hasLength(1)),
    );

    blocTest<RegisterCubit, SubmitState<SignUpOutcome>>(
      'reports that email confirmation is required',
      build: () => RegisterCubit(repo),
      act: (c) => c.submit(fullName: 'Sara', email: 'a@b.co', password: 'travel2026'),
      expect: () => [
        const SubmitState<SignUpOutcome>(status: SubmitStatus.submitting),
        const SubmitState<SignUpOutcome>(
          status: SubmitStatus.success,
          result: SignUpOutcome.confirmationRequired,
        ),
      ],
    );
  });
}
