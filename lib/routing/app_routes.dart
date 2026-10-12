/// Every route path in one place. Paths double as deep-link paths:
/// `rahala://rahala.app/<path>`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  /// Target of email-confirmation / password-recovery links. Supabase
  /// exchanges the code; routing then follows the session state.
  static const authCallback = '/auth-callback';

  // Bottom-navigation tabs.
  static const home = '/home';
  static const explore = '/explore';
  static const bookings = '/bookings';
  static const favorites = '/favorites';
  static const account = '/account';

  /// The tab roots, in bottom-navigation order.
  static const tabs = [home, explore, bookings, favorites, account];

  /// Explore, optionally pre-filtered to a category or with search focused.
  static String exploreWith({String? category, bool search = false}) {
    final query = {if (category != null) 'category': category, if (search) 'search': '1'};
    return Uri(path: explore, queryParameters: query.isEmpty ? null : query).toString();
  }

  static const editProfile = '/account/edit';

  /// Legacy browse path; redirects to [explore]. Kept because destination
  /// links live under it.
  static const destinations = '/destinations';

  /// Details of one destination: `/destinations/<id>` (also a deep link).
  static String destination(String id) => '$destinations/${Uri.encodeComponent(id)}';

  /// Booking flow for a destination, optionally with a package preselected.
  static String book(String destinationId, {String? packageId}) => Uri(
        path: '${destination(destinationId)}/book',
        queryParameters: packageId == null ? null : {'package': packageId},
      ).toString();

  static String booking(String id) => '$bookings/${Uri.encodeComponent(id)}';
  static String bookingConfirmation(String id) => '${booking(id)}/confirmation';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const credits = '/settings/credits';

  /// Only reachable while signed out.
  static const guestOnly = {onboarding, login, register, forgotPassword};

  /// Reachable regardless of session state.
  static const public = {splash, authCallback};
}
