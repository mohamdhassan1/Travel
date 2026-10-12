import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/routing/app_routes.dart';
import 'package:rahala/routing/route_guard.dart';

void main() {
  String? redirect(
    String location, {
    SessionStatus status = SessionStatus.unauthenticated,
    bool onboarded = true,
    bool recovery = false,
  }) =>
      resolveRedirect(
        uri: Uri.parse(location),
        status: status,
        onboardingCompleted: onboarded,
        passwordRecovery: recovery,
      );

  const signedIn = SessionStatus.authenticated;

  group('while the session is unknown', () {
    test('everything waits on the splash screen', () {
      expect(
        redirect(AppRoutes.account, status: SessionStatus.unknown),
        AppRoutes.splash,
      );
      expect(redirect(AppRoutes.splash, status: SessionStatus.unknown), isNull);
    });
  });

  group('startup routing from splash', () {
    test('first launch goes to onboarding', () {
      expect(
        redirect(AppRoutes.splash, onboarded: false),
        AppRoutes.onboarding,
      );
    });
    test('returning signed-out user goes to login', () {
      expect(redirect(AppRoutes.splash), AppRoutes.login);
    });
    test('restored session goes home', () {
      expect(redirect(AppRoutes.splash, status: signedIn), AppRoutes.home);
    });
    test('auth callback deep link follows the session', () {
      expect(redirect(AppRoutes.authCallback), AppRoutes.login);
      expect(
        redirect('${AppRoutes.authCallback}?code=abc', status: signedIn),
        AppRoutes.home,
      );
    });
  });

  group('protected routes', () {
    test('signed-out users are sent to login, remembering the target', () {
      final target = redirect('${AppRoutes.settings}?tab=1');
      final uri = Uri.parse(target!);
      expect(uri.path, AppRoutes.login);
      expect(uri.queryParameters['from'], '${AppRoutes.settings}?tab=1');
    });
    test('signed-in users pass through', () {
      expect(redirect(AppRoutes.settings, status: signedIn), isNull);
    });
  });

  group('guest-only routes', () {
    test('are open to signed-out users', () {
      for (final route in AppRoutes.guestOnly) {
        expect(redirect(route), isNull, reason: route);
      }
    });
    test('send signed-in users home', () {
      expect(redirect(AppRoutes.login, status: signedIn), AppRoutes.home);
      expect(redirect(AppRoutes.register, status: signedIn), AppRoutes.home);
    });
    test('continue to the remembered deep link after sign-in', () {
      final login = Uri(
        path: AppRoutes.login,
        queryParameters: {'from': AppRoutes.settings},
      ).toString();
      expect(redirect(login, status: signedIn), AppRoutes.settings);
    });
  });

  test('a recovery session is confined to the reset screen', () {
    expect(
      redirect(AppRoutes.account, status: signedIn, recovery: true),
      AppRoutes.resetPassword,
    );
    expect(
      redirect(AppRoutes.resetPassword, status: signedIn, recovery: true),
      isNull,
    );
  });

  group('safeReturnPath rejects open redirects', () {
    test('accepts in-app paths', () {
      expect(safeReturnPath('/settings'), '/settings');
      expect(safeReturnPath('/settings/credits?x=1'), '/settings/credits?x=1');
    });
    test('rejects external or auth targets', () {
      for (final bad in [
        null,
        '',
        'settings',
        '//evil.com',
        'https://evil.com',
        AppRoutes.login,
        AppRoutes.splash,
      ]) {
        expect(safeReturnPath(bad), isNull, reason: '$bad');
      }
    });
  });
}
