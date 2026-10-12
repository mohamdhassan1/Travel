// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Rahala';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonGoHome => 'Go to home';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonSystemDefault => 'System default';

  @override
  String get errorNetwork => 'You appear to be offline. Check your connection and try again.';

  @override
  String get errorTimeout => 'The server is taking too long to respond. Please try again.';

  @override
  String get errorServer => 'Something went wrong on our side. Please try again in a moment.';

  @override
  String get errorUnknown => 'Something unexpected happened. Please try again.';

  @override
  String get errorPermissionDenied => 'You don\'t have permission to do that.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorSessionExpired => 'Your session has expired. Please sign in again.';

  @override
  String get errorRateLimited => 'Too many attempts. Please wait a minute and try again.';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String validationPasswordTooShort(int min) {
    return 'Use at least $min characters';
  }

  @override
  String get validationPasswordWeak => 'Include at least one letter and one number';

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match';

  @override
  String get validationNameTooShort => 'Enter at least 2 characters';

  @override
  String validationNameTooLong(int max) {
    return 'Keep it under $max characters';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboarding1Title => 'Discover places that move you';

  @override
  String get onboarding1Body => 'Hand-picked destinations with honest details, local seasons and live weather.';

  @override
  String get onboarding2Title => 'Plan every detail in one place';

  @override
  String get onboarding2Body =>
      'Compare packages, choose your dates and travellers, and review the full price before you book.';

  @override
  String get onboarding3Title => 'Travel with timely reminders';

  @override
  String get onboarding3Body => 'Keep your trips organised and get reminders before you depart.';

  @override
  String get onboardingCreateAccount => 'Create an account';

  @override
  String get onboardingHaveAccount => 'I already have an account';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameHint => 'As it appears on your ID';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordRequirements => 'At least 8 characters, with letters and numbers.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue planning your trips.';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginNoAccount => 'New to Rahala?';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get loginResendConfirmation => 'Resend confirmation email';

  @override
  String get loginConfirmationResent => 'Confirmation email sent. Check your inbox.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Save favourites, book trips and keep everything in sync.';

  @override
  String get registerButton => 'Create account';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerSignIn => 'Sign in';

  @override
  String get registerCheckInboxTitle => 'Check your inbox';

  @override
  String registerCheckInboxBody(String email) {
    return 'If $email isn\'t registered yet, we\'ve sent a confirmation link to it. Open the link to activate your account, then sign in.';
  }

  @override
  String get registerResend => 'Resend email';

  @override
  String registerResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get registerBackToSignIn => 'Back to sign in';

  @override
  String get registerEmailResent => 'We\'ve sent the email again.';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotSubtitle => 'Enter the email you signed up with and we\'ll send you a secure reset link.';

  @override
  String get forgotButton => 'Send reset link';

  @override
  String get forgotSentTitle => 'Check your email';

  @override
  String forgotSentBody(String email) {
    return 'If an account exists for $email, a password reset link is on its way. Open it on this device to choose a new password.';
  }

  @override
  String get resetTitle => 'Choose a new password';

  @override
  String get resetSubtitle => 'You\'re signed in through a secure reset link. Set a new password to finish.';

  @override
  String get resetButton => 'Update password';

  @override
  String get resetSuccess => 'Your password has been updated.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailNotConfirmed => 'Please confirm your email address before signing in.';

  @override
  String get authErrorEmailInUse => 'An account with this email already exists. Try signing in instead.';

  @override
  String get authErrorWeakPassword => 'That password is too weak. Choose a longer, less common one.';

  @override
  String get authErrorSamePassword => 'Your new password must be different from the old one.';

  @override
  String get authErrorSignupDisabled => 'New sign-ups are currently disabled.';

  @override
  String get sessionEndedBanner => 'You\'ve been signed out. Please sign in again.';

  @override
  String get accountEmailVerified => 'Email verified';

  @override
  String get accountEmailNotVerified => 'Email not verified';

  @override
  String accountMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get accountSectionAbout => 'About';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutConfirmTitle => 'Sign out?';

  @override
  String get accountSignOutConfirmBody => 'You\'ll need to sign in again to see your trips and favourites.';

  @override
  String get accountSignedOutLocally =>
      'Signed out on this device. We couldn\'t reach the server to end other sessions.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPhotoCredits => 'Photo credits';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get creditsTitle => 'Photo credits';

  @override
  String get creditsIntro => 'Photos are used under their original licences. Thank you to the photographers.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundBody => 'The link you followed may be broken or the page may have moved.';

  @override
  String get configErrorTitle => 'App configuration required';

  @override
  String get configErrorMissing =>
      'This build doesn\'t include backend settings. Run the app with --dart-define-from-file=env/dev.json (see README).';

  @override
  String get configErrorInvalidUrl => 'The configured Supabase URL is not a valid https URL.';

  @override
  String get configErrorSecretKey =>
      'A secret/service-role key was supplied. Only the publishable key may be used in the app.';

  @override
  String get errorInvalidData => 'We received data we couldn\'t read. Please try again later.';

  @override
  String get destinationsEmptyTitle => 'No destinations yet';

  @override
  String get destinationsEmptyBody => 'The catalog is empty right now. Check back soon.';

  @override
  String get destinationsErrorTitle => 'Couldn\'t load destinations';

  @override
  String get destinationFeatured => 'Featured';

  @override
  String destinationFromPrice(String price) {
    return 'From $price';
  }

  @override
  String get destinationPerPerson => 'per person';

  @override
  String get destinationNoPackages => 'No packages available yet';

  @override
  String destinationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String destinationDaysRange(int min, int max) {
    return '$min–$max days';
  }

  @override
  String get destinationImageUnavailable => 'Image unavailable';

  @override
  String get accountBrowseDestinations => 'Browse destinations';

  @override
  String get profileLoadError => 'We couldn\'t load your profile details.';

  @override
  String get detailsAbout => 'About';

  @override
  String get detailsBestSeason => 'Best time to visit';

  @override
  String get detailsCoordinates => 'Coordinates';

  @override
  String get detailsGallery => 'Gallery';

  @override
  String detailsGalleryPhoto(int index, int total) {
    return 'Photo $index of $total';
  }

  @override
  String detailsPhotoCredit(String credit) {
    return 'Photos: $credit';
  }

  @override
  String get detailsPackagesTitle => 'Packages';

  @override
  String get detailsPackagesEmpty => 'No packages are available for this destination right now.';

  @override
  String get detailsPackagesError => 'Couldn\'t load packages.';

  @override
  String get detailsNotFoundTitle => 'Destination not found';

  @override
  String get detailsNotFoundBody => 'It may no longer be available, or the link is incorrect.';

  @override
  String get detailsErrorTitle => 'Couldn\'t load this destination';

  @override
  String get detailsBackToDestinations => 'Back to destinations';

  @override
  String get detailsPriceNote => 'Sample prices per person. No payment is taken in this app.';

  @override
  String get packageIncludes => 'What\'s included';

  @override
  String packageMaxTravelers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count travellers',
      one: 'Up to 1 traveller',
    );
    return '$_temp0';
  }

  @override
  String get favoritesTitle => 'Favourites';

  @override
  String get favoritesEmptyTitle => 'No favourites yet';

  @override
  String get favoritesEmptyBody => 'Tap the heart on any destination to save it here.';

  @override
  String get favoritesErrorTitle => 'Couldn\'t load your favourites';

  @override
  String get favoriteAdd => 'Add to favourites';

  @override
  String get favoriteRemove => 'Remove from favourites';

  @override
  String get favoriteAdded => 'Saved to favourites';

  @override
  String get favoriteRemoved => 'Removed from favourites';

  @override
  String favoriteAddFailed(String reason) {
    return 'Couldn\'t save to favourites. $reason';
  }

  @override
  String favoriteRemoveFailed(String reason) {
    return 'Couldn\'t remove from favourites. $reason';
  }

  @override
  String get commonUndo => 'Undo';

  @override
  String get errorInvalidInput => 'Some of the details you entered aren\'t valid. Please check them and try again.';

  @override
  String get bookingErrorPackageUnavailable => 'This package is no longer available. Please choose another one.';

  @override
  String get bookingErrorTooManyTravelers => 'This package doesn\'t allow that many travellers.';

  @override
  String get bookingErrorInvalidDate => 'Please choose a travel date between tomorrow and one year from now.';

  @override
  String get bookingErrorNotCancellable => 'This booking can no longer be cancelled.';

  @override
  String get validationPhoneInvalid => 'Enter a valid phone number (digits, spaces, + ( ) -)';

  @override
  String validationTextTooLong(int max) {
    return 'Keep it under $max characters';
  }

  @override
  String get packageBookCta => 'Book this package';

  @override
  String get bookingTitle => 'Book your trip';

  @override
  String get bookingPackageLabel => 'Package';

  @override
  String get bookingPackageRequired => 'Choose a package';

  @override
  String get bookingNoPackages => 'This destination has no bookable packages right now.';

  @override
  String get bookingLoadErrorTitle => 'Couldn\'t load booking options';

  @override
  String get bookingTravelDateLabel => 'Travel date';

  @override
  String get bookingTravelDatePick => 'Choose a date';

  @override
  String get bookingTravelDateHint => 'You can book from tomorrow up to one year ahead.';

  @override
  String get bookingTravelDateRequired => 'Choose a travel date';

  @override
  String get bookingTravelersLabel => 'Travellers';

  @override
  String bookingTravelersMax(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This package allows up to $count travellers.',
      one: 'This package is for 1 traveller.',
    );
    return '$_temp0';
  }

  @override
  String get bookingTravelersDecrease => 'Fewer travellers';

  @override
  String get bookingTravelersIncrease => 'More travellers';

  @override
  String bookingTravelersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count travellers',
      one: '1 traveller',
    );
    return '$_temp0';
  }

  @override
  String get bookingContactSection => 'Contact details';

  @override
  String get bookingContactName => 'Lead traveller\'s full name';

  @override
  String get bookingContactPhone => 'Phone number';

  @override
  String get bookingContactPhoneHint => '+20 100 000 0000';

  @override
  String get bookingSpecialRequests => 'Special requests (optional)';

  @override
  String get bookingSpecialRequestsHint => 'Dietary needs, accessibility, room preferences…';

  @override
  String get bookingContinueToReview => 'Review booking';

  @override
  String get bookingReviewTitle => 'Review your booking';

  @override
  String get bookingReviewEdit => 'Edit details';

  @override
  String get bookingPricePerPerson => 'Price per person';

  @override
  String get bookingTotal => 'Total';

  @override
  String get bookingTotalNote =>
      'The final amount is calculated by our server from the package price when you confirm.';

  @override
  String get bookingNoPaymentNote =>
      'No payment is taken in this app, and availability isn\'t checked in real time. Confirming records your reservation.';

  @override
  String get bookingConfirmCta => 'Confirm booking';

  @override
  String get bookingConfirmedTitle => 'Booking confirmed';

  @override
  String get bookingConfirmedBody => 'Your reservation has been recorded. Keep your reference for any questions.';

  @override
  String get bookingReference => 'Reference';

  @override
  String get bookingViewMyBookings => 'View my bookings';

  @override
  String get bookingDone => 'Done';

  @override
  String get myBookingsTitle => 'My bookings';

  @override
  String get myBookingsFilterUpcoming => 'Upcoming';

  @override
  String get myBookingsFilterPast => 'Past';

  @override
  String get myBookingsFilterCancelled => 'Cancelled';

  @override
  String get myBookingsEmptyTitle => 'No bookings yet';

  @override
  String get myBookingsEmptyBody => 'When you book a trip, it will appear here.';

  @override
  String get myBookingsNoUpcoming => 'You have no upcoming trips.';

  @override
  String get myBookingsNoPast => 'You have no past trips.';

  @override
  String get myBookingsNoCancelled => 'You have no cancelled bookings.';

  @override
  String get myBookingsErrorTitle => 'Couldn\'t load your bookings';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingPastTrip => 'Past trip';

  @override
  String get bookingDetailsTitle => 'Booking details';

  @override
  String bookingBookedOn(String date) {
    return 'Booked on $date';
  }

  @override
  String bookingCancelledOn(String date) {
    return 'Cancelled on $date';
  }

  @override
  String get bookingContact => 'Contact';

  @override
  String get bookingCancelCta => 'Cancel booking';

  @override
  String get bookingCancelConfirmTitle => 'Cancel this booking?';

  @override
  String bookingCancelConfirmBody(String destination, String date) {
    return 'This can\'t be undone. Your reservation for $destination on $date will be cancelled.';
  }

  @override
  String get bookingCancelKeep => 'Keep booking';

  @override
  String get bookingCancelledToast => 'Booking cancelled';

  @override
  String bookingCancelFailed(String reason) {
    return 'Couldn\'t cancel the booking. $reason';
  }

  @override
  String get bookingCancelPolicy => 'Bookings can be cancelled until the day before travel.';

  @override
  String get bookingCatalogItemUnavailable => 'No longer listed in the catalog';

  @override
  String get bookingNotFoundTitle => 'Booking not found';

  @override
  String get bookingNotFoundBody => 'It may belong to another account, or the link is incorrect.';

  @override
  String get bookingErrorTitle => 'Couldn\'t load this booking';

  @override
  String get bookingErrorIdempotencyConflict =>
      'This booking request matches an earlier one with different details. Check My bookings, then try again.';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody => 'When you book or cancel a trip, the update will appear here.';

  @override
  String get notificationsErrorTitle => 'Couldn\'t load notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String notificationsActionFailed(String error) {
    return 'Couldn\'t update notifications. $error';
  }

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
      zero: 'No unread notifications',
    );
    return '$_temp0';
  }

  @override
  String get notificationUnread => 'Unread';

  @override
  String get notificationBookingConfirmedTitle => 'Booking confirmed';

  @override
  String get notificationBookingCancelledTitle => 'Booking cancelled';

  @override
  String get notificationTripReminderTitle => 'Trip reminder';

  @override
  String notificationTripOn(String destination, String date) {
    return '$destination on $date';
  }

  @override
  String notificationReference(String reference) {
    return 'Ref. $reference';
  }

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsTripReminders => 'Trip reminders';

  @override
  String get settingsTripRemindersSubtitle => 'On this device, at 9:00 the day before each confirmed trip';

  @override
  String get settingsNotificationsUnsupported =>
      'Trip reminders and push notifications aren\'t available on this platform.';

  @override
  String get settingsNotificationsAllowHint => 'Allow notifications so trip reminders can appear.';

  @override
  String get settingsNotificationsAllow => 'Allow';

  @override
  String get settingsNotificationsBlocked => 'Notifications are turned off for Rahala in your device settings.';

  @override
  String get settingsNotificationsOpenSettings => 'Open settings';

  @override
  String get notificationsPermissionDeniedToast =>
      'Notifications weren\'t allowed. You can turn them on later in your device settings.';

  @override
  String get tripReminderChannelName => 'Trip reminders';

  @override
  String get tripReminderChannelDescription => 'Reminders the day before your booked trips';

  @override
  String tripReminderTitle(String destination) {
    return 'Your trip to $destination is tomorrow';
  }

  @override
  String get tripReminderTitleGeneric => 'Your trip is tomorrow';

  @override
  String tripReminderBody(String package, String date, String reference) {
    return '$package · $date · Ref. $reference';
  }

  @override
  String tripReminderBodyNoPackage(String date, String reference) {
    return '$date · Ref. $reference';
  }

  @override
  String get commonView => 'View';

  @override
  String get pushForegroundBookingConfirmed => 'Booking confirmed';

  @override
  String get pushForegroundBookingCancelled => 'Booking cancelled';

  @override
  String get bookingUpdatesChannelName => 'Booking updates';

  @override
  String get bookingUpdatesChannelDescription => 'Confirmations and cancellations of your bookings';

  @override
  String get settingsPushTitle => 'Booking updates';

  @override
  String get settingsPushOn => 'Confirmations and cancellations are sent to this device.';

  @override
  String get settingsPushNeedsPermission => 'Allow notifications to get booking updates on this device.';

  @override
  String get settingsPushUnavailable => 'Push notifications aren\'t set up for this device yet.';

  @override
  String get settingsPushNotRegistered =>
      'This device isn\'t registered for booking updates yet. Rahala will retry when you reopen the app.';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navTrips => 'Trips';

  @override
  String get navSaved => 'Saved';

  @override
  String get navProfile => 'Profile';

  @override
  String get listSeparator => ', ';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeHeadline => 'Where to next?';

  @override
  String homeNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count unread',
      one: 'Notifications, 1 unread',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchHint => 'Search destinations or countries';

  @override
  String get homeNextTrip => 'Your next trip';

  @override
  String get homeSeeAllTrips => 'All trips';

  @override
  String get homeTripToday => 'Today';

  @override
  String get homeTripTomorrow => 'Tomorrow';

  @override
  String homeTripInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String get homeTripsError => 'Couldn\'t load your trips.';

  @override
  String get homeNoTripTitle => 'No upcoming trips';

  @override
  String get homeNoTripBody => 'Your next adventure starts with a destination.';

  @override
  String get homeNoTripCta => 'Explore';

  @override
  String get homeCategories => 'Browse by type';

  @override
  String get homeFeatured => 'Featured destinations';

  @override
  String get homeFeaturedSubtitle => 'Hand-picked from the Rahala catalog';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeRecentlyViewed => 'Recently viewed';

  @override
  String homeSavedShortcut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved destinations',
      one: '1 saved destination',
    );
    return '$_temp0';
  }

  @override
  String get homeMoreToExplore => 'More to explore';

  @override
  String get homeMoreToExploreSubtitle => 'Every other destination in the catalog';

  @override
  String get homeCatalogError => 'Couldn\'t load destinations.';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSearchHint => 'Destination, country or experience';

  @override
  String get exploreClearSearch => 'Clear search';

  @override
  String get exploreFilters => 'Filters';

  @override
  String get exploreAllCategories => 'All';

  @override
  String exploreResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count destinations',
      one: '1 destination',
    );
    return '$_temp0';
  }

  @override
  String get exploreSort => 'Sort';

  @override
  String get exploreSortFeatured => 'Featured first';

  @override
  String get exploreSortPriceLow => 'Price: low to high';

  @override
  String get exploreSortPriceHigh => 'Price: high to low';

  @override
  String get exploreSortName => 'Name (A–Z)';

  @override
  String get exploreNoResultsTitle => 'No matching destinations';

  @override
  String exploreNoResultsBody(String query) {
    return 'Nothing matches “$query”. Try another name or country, or clear the filters.';
  }

  @override
  String get exploreNoResultsFiltersBody => 'No destination fits these filters. Try widening them.';

  @override
  String get exploreClearAll => 'Clear search & filters';

  @override
  String get exploreMaxPrice => 'Starting price per person';

  @override
  String get exploreAnyPrice => 'Any price';

  @override
  String explorePriceUpTo(String price) {
    return 'Up to $price';
  }

  @override
  String get explorePriceNote => 'Based on each destination\'s cheapest package. Prices are sample catalog prices.';

  @override
  String get exploreTripLength => 'Trip length';

  @override
  String get exploreLengthShort => 'Short break (1–3 days)';

  @override
  String get exploreLengthMedium => '4–6 days';

  @override
  String get exploreLengthLong => 'A week or more';

  @override
  String get exploreReset => 'Reset';

  @override
  String get exploreApply => 'Show results';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileSave => 'Save changes';

  @override
  String get profileSaved => 'Profile updated.';

  @override
  String get profileSaveFailed => 'Couldn\'t save your profile.';

  @override
  String get profileDiscardTitle => 'Discard changes?';

  @override
  String get profileDiscardBody => 'Your edits haven\'t been saved.';

  @override
  String get profileDiscard => 'Discard';

  @override
  String get profileKeepEditing => 'Keep editing';

  @override
  String get profilePhoneLabel => 'Phone (optional)';

  @override
  String get profilePhoneHint => 'e.g. +20 100 000 0000';

  @override
  String get profileEmailReadOnly => 'Your sign-in email can\'t be changed here.';

  @override
  String get profileStatsError => 'Couldn\'t load your trip statistics.';

  @override
  String get profilePhotoChange => 'Change photo';

  @override
  String get profilePhotoGallery => 'Choose from gallery';

  @override
  String get profilePhotoCamera => 'Take a photo';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String get profilePhotoFailed => 'Couldn\'t update your photo.';

  @override
  String get profilePhotoTooLarge => 'That photo is too large (max 2 MB). Try another one.';

  @override
  String get profilePhotoPickFailed => 'Couldn\'t open the photo picker. Check the app\'s permissions.';

  @override
  String get levelTitle => 'Traveler level';

  @override
  String get levelNewTraveler => 'New traveler';

  @override
  String get levelExplorer => 'Explorer';

  @override
  String get levelVoyager => 'Voyager';

  @override
  String get levelGlobetrotter => 'Globetrotter';

  @override
  String get levelHowItWorks => 'How levels work';

  @override
  String get levelProgress => 'Progress to the next level';

  @override
  String get levelTopReached => 'You\'ve reached the top level. Happy travels!';

  @override
  String levelNextHint(String missing, String level) {
    return '$missing to become $level.';
  }

  @override
  String levelTripsMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more completed trips',
      one: '1 more completed trip',
    );
    return '$_temp0';
  }

  @override
  String levelCountriesMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more countries',
      one: '1 more country',
    );
    return '$_temp0';
  }

  @override
  String get levelRulesIntro =>
      'Your level comes only from trips you have actually taken with Rahala: confirmed bookings whose travel date has passed. Cancelled bookings don\'t count.';

  @override
  String get levelRuleStart => 'Where everyone starts';

  @override
  String levelRule(String trips, String countries) {
    return '$trips in $countries';
  }

  @override
  String levelTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed trips',
      one: '1 completed trip',
    );
    return '$_temp0';
  }

  @override
  String levelCountriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count different countries',
      one: '1 country',
    );
    return '$_temp0';
  }

  @override
  String get levelRulesNote =>
      'This isn\'t a rating from other people — Rahala has no reviews. It simply reflects your own travel history.';

  @override
  String get statsCompleted => 'Trips taken';

  @override
  String get statsUpcoming => 'Upcoming';

  @override
  String get statsDestinations => 'Destinations visited';

  @override
  String get statsCountries => 'Countries visited';

  @override
  String statsFootnote(int total, int cancelled) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Based on your $total bookings',
      one: 'Based on your 1 booking',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cancelled,
      locale: localeName,
      other: '$cancelled cancelled',
      one: '1 cancelled',
      zero: 'none cancelled',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get statsNoBookings => 'No bookings yet — your statistics will appear after your first trip.';

  @override
  String get weatherTitle => 'Weather now';

  @override
  String get weatherUnavailable => 'Weather is unavailable right now.';

  @override
  String get weatherSource => 'Live weather at the destination · data by Open-Meteo.com';

  @override
  String weatherDegrees(int value) {
    return '$value°C';
  }

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherShowers => 'Showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherUnknown => 'Weather';

  @override
  String get detailsShare => 'Share';

  @override
  String detailsShareText(String name, String country, String summary, String link) {
    return '$name, $country — $summary\nOpen in Rahala: $link';
  }

  @override
  String get detailsShareUnavailable => 'Sharing isn\'t available on this device.';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteBody =>
      'This permanently deletes your profile, photo, bookings, saved destinations and notifications from Rahala. It can\'t be undone.';

  @override
  String get accountDeleteConfirmCheck => 'I understand this can\'t be undone';

  @override
  String get accountDeleteCta => 'Delete permanently';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String accountDeleteFailed(String reason) {
    return 'Couldn\'t delete your account. $reason';
  }

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get accountChangePassword => 'Change password';

  @override
  String get changePasswordTitle => 'Change your password';

  @override
  String get changePasswordSubtitle => 'Choose a new password for your account. You\'ll stay signed in on this device.';

  @override
  String get bookingErrorRateLimited => 'You\'ve made several bookings in the last hour. Please try again later.';

  @override
  String get bookingViewDestination => 'View destination';

  @override
  String favoritesRefreshFailed(String reason) {
    return 'Couldn\'t refresh your saved destinations. $reason';
  }
}
