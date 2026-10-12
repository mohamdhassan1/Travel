import '../logic/auth/session_cubit.dart';
import 'app_routes.dart';

/// Pure routing policy — kept free of Flutter/GoRouter types so it can be
/// unit-tested exhaustively.
///
/// Returns the location to redirect to, or `null` to allow [uri].
String? resolveRedirect({
  required Uri uri,
  required SessionStatus status,
  required bool onboardingCompleted,
  required bool passwordRecovery,
}) {
  final path = uri.path.isEmpty ? '/' : uri.path;

  // Session not restored yet: hold on the splash screen.
  if (status == SessionStatus.unknown) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final signedIn = status == SessionStatus.authenticated;

  // A recovery session may only be used to set a new password.
  if (signedIn && passwordRecovery) {
    return path == AppRoutes.resetPassword ? null : AppRoutes.resetPassword;
  }

  if (path == AppRoutes.splash || path == AppRoutes.authCallback || path == '/') {
    if (signedIn) return AppRoutes.home;
    return onboardingCompleted ? AppRoutes.login : AppRoutes.onboarding;
  }

  if (AppRoutes.guestOnly.contains(path)) {
    if (!signedIn) return null;
    // After signing in, continue to the page the user originally asked for.
    return safeReturnPath(uri.queryParameters['from']) ?? AppRoutes.home;
  }

  if (AppRoutes.public.contains(path)) return null;

  // Everything else requires a session.
  if (!signedIn) {
    final from = uri.toString();
    return Uri(
      path: AppRoutes.login,
      queryParameters: {'from': from},
    ).toString();
  }
  return null;
}

/// Accepts only in-app absolute paths (no scheme/host, no protocol-relative
/// `//evil.com`, no auth screens) to avoid open-redirect tricks.
String? safeReturnPath(String? from) {
  if (from == null || from.isEmpty) return null;
  if (!from.startsWith('/') || from.startsWith('//')) return null;
  final parsed = Uri.tryParse(from);
  if (parsed == null || parsed.hasScheme || parsed.hasAuthority) return null;
  if (AppRoutes.guestOnly.contains(parsed.path) || AppRoutes.public.contains(parsed.path)) return null;
  return from;
}
