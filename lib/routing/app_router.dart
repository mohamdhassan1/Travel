import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/auth/session_cubit.dart';
import '../logic/settings/settings_cubit.dart';
import '../presentation/account/credits_screen.dart';
import '../presentation/account/settings_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/auth/reset_password_screen.dart';
import '../presentation/booking/booking_confirmation_screen.dart';
import '../presentation/booking/booking_details_screen.dart';
import '../presentation/booking/booking_form_screen.dart';
import '../presentation/booking/my_bookings_screen.dart';
import '../presentation/catalog/destination_details_screen.dart';
import '../presentation/common/not_found_screen.dart';
import '../presentation/explore/explore_screen.dart';
import '../presentation/favorites/favorites_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/profile/edit_profile_screen.dart';
import '../presentation/profile/profile_screen.dart';
import '../presentation/shell/main_shell.dart';
import '../presentation/splash/splash_screen.dart';
import 'app_routes.dart';
import 'route_guard.dart';

GoRouter createAppRouter({
  required SessionCubit session,
  required SettingsCubit settings,
  String initialLocation = AppRoutes.splash,
}) {
  // Pages above the tab shell (details, booking flow) use this navigator.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    refreshListenable: _StreamsListenable([session.stream, settings.stream]),
    redirect: (context, state) => resolveRedirect(
      uri: state.uri,
      status: session.state.status,
      onboardingCompleted: settings.state.onboardingCompleted,
      passwordRecovery: session.state.passwordRecovery,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.splash),
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      // Only visible for a moment while Supabase exchanges the link's code.
      GoRoute(
        path: AppRoutes.authCallback,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      // Signed-in app: five tabs, each with its own navigation stack (scroll
      // positions and nested pages survive tab switches).
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, pageBuilder: (_, state) => _fade(state, const HomeScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.explore,
              pageBuilder: (_, state) => _fade(
                state,
                ExploreScreen(
                  categoryId: state.uri.queryParameters['category'],
                  focusSearch: state.uri.queryParameters['search'] == '1',
                ),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.bookings,
              pageBuilder: (_, state) => _fade(state, const MyBookingsScreen()),
              routes: [
                // Details cover the tab bar (root navigator); the path stays
                // /bookings/<id> for push-notification and deep links.
                GoRoute(
                  path: ':bookingId',
                  parentNavigatorKey: rootKey,
                  builder: (_, state) => BookingDetailsScreen(bookingId: state.pathParameters['bookingId']!),
                  routes: [
                    GoRoute(
                      path: 'confirmation',
                      parentNavigatorKey: rootKey,
                      builder: (_, state) => BookingConfirmationScreen(bookingId: state.pathParameters['bookingId']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.favorites, pageBuilder: (_, state) => _fade(state, const FavoritesScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.account,
              pageBuilder: (_, state) => _fade(state, const ProfileScreen()),
              routes: [
                GoRoute(path: 'edit', parentNavigatorKey: rootKey, builder: (_, __) => const EditProfileScreen()),
              ],
            ),
          ]),
        ],
      ),
      // Full-screen pages above the tabs.
      GoRoute(
        path: AppRoutes.destinations,
        // The old browse list now lives in Explore.
        redirect: (_, state) => state.uri.path == AppRoutes.destinations ? AppRoutes.explore : null,
        routes: [
          GoRoute(
            path: ':destinationId',
            builder: (_, state) => DestinationDetailsScreen(destinationId: state.pathParameters['destinationId']!),
            routes: [
              GoRoute(
                path: 'book',
                builder: (_, state) => BookingFormScreen(
                  destinationId: state.pathParameters['destinationId']!,
                  initialPackageId: state.uri.queryParameters['package'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'credits', builder: (_, __) => const CreditsScreen()),
        ],
      ),
    ],
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
    );

/// Re-evaluates redirects whenever session or settings state changes.
class _StreamsListenable extends ChangeNotifier {
  _StreamsListenable(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final s in streams) s.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
