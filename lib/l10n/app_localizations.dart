import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Rahala'**
  String get appName;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get commonGoHome;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get commonSystemDefault;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server is taking too long to respond. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again in a moment.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorPermissionDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute and try again.'**
  String get errorRateLimited;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters'**
  String validationPasswordTooShort(int min);

  /// No description provided for @validationPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Include at least one letter and one number'**
  String get validationPasswordWeak;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get validationPasswordMismatch;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get validationNameTooShort;

  /// No description provided for @validationNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters'**
  String validationNameTooLong(int max);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Discover places that move you'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Hand-picked destinations with honest details, local seasons and live weather.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Plan every detail in one place'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Compare packages, choose your dates and travellers, and review the full price before you book.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Travel with timely reminders'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Keep your trips organised and get reminders before you depart.'**
  String get onboarding3Body;

  /// No description provided for @onboardingCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get onboardingCreateAccount;

  /// No description provided for @onboardingHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get onboardingHaveAccount;

  /// No description provided for @onboardingPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageLabel(int current, int total);

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'As it appears on your ID'**
  String get authFullNameHint;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with letters and numbers.'**
  String get authPasswordRequirements;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue planning your trips.'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Rahala?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccount;

  /// No description provided for @loginResendConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation email'**
  String get loginResendConfirmation;

  /// No description provided for @loginConfirmationResent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent. Check your inbox.'**
  String get loginConfirmationResent;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save favourites, book trips and keep everything in sync.'**
  String get registerSubtitle;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get registerSignIn;

  /// No description provided for @registerCheckInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get registerCheckInboxTitle;

  /// No description provided for @registerCheckInboxBody.
  ///
  /// In en, this message translates to:
  /// **'If {email} isn\'t registered yet, we\'ve sent a confirmation link to it. Open the link to activate your account, then sign in.'**
  String registerCheckInboxBody(String email);

  /// No description provided for @registerResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get registerResend;

  /// No description provided for @registerResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String registerResendIn(int seconds);

  /// No description provided for @registerBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get registerBackToSignIn;

  /// No description provided for @registerEmailResent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent the email again.'**
  String get registerEmailResent;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with and we\'ll send you a secure reset link.'**
  String get forgotSubtitle;

  /// No description provided for @forgotButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotButton;

  /// No description provided for @forgotSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotSentTitle;

  /// No description provided for @forgotSentBody.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a password reset link is on its way. Open it on this device to choose a new password.'**
  String forgotSentBody(String email);

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in through a secure reset link. Set a new password to finish.'**
  String get resetSubtitle;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetButton;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get resetSuccess;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address before signing in.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try signing in instead.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is too weak. Choose a longer, less common one.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorSamePassword.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from the old one.'**
  String get authErrorSamePassword;

  /// No description provided for @authErrorSignupDisabled.
  ///
  /// In en, this message translates to:
  /// **'New sign-ups are currently disabled.'**
  String get authErrorSignupDisabled;

  /// No description provided for @sessionEndedBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been signed out. Please sign in again.'**
  String get sessionEndedBanner;

  /// No description provided for @accountEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get accountEmailVerified;

  /// No description provided for @accountEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get accountEmailNotVerified;

  /// No description provided for @accountMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String accountMemberSince(String date);

  /// No description provided for @accountSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get accountSectionAbout;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutConfirmTitle;

  /// No description provided for @accountSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to see your trips and favourites.'**
  String get accountSignOutConfirmBody;

  /// No description provided for @accountSignedOutLocally.
  ///
  /// In en, this message translates to:
  /// **'Signed out on this device. We couldn\'t reach the server to end other sessions.'**
  String get accountSignedOutLocally;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsPhotoCredits.
  ///
  /// In en, this message translates to:
  /// **'Photo credits'**
  String get settingsPhotoCredits;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo credits'**
  String get creditsTitle;

  /// No description provided for @creditsIntro.
  ///
  /// In en, this message translates to:
  /// **'Photos are used under their original licences. Thank you to the photographers.'**
  String get creditsIntro;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The link you followed may be broken or the page may have moved.'**
  String get notFoundBody;

  /// No description provided for @configErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'App configuration required'**
  String get configErrorTitle;

  /// No description provided for @configErrorMissing.
  ///
  /// In en, this message translates to:
  /// **'This build doesn\'t include backend settings. Run the app with --dart-define-from-file=env/dev.json (see README).'**
  String get configErrorMissing;

  /// No description provided for @configErrorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'The configured Supabase URL is not a valid https URL.'**
  String get configErrorInvalidUrl;

  /// No description provided for @configErrorSecretKey.
  ///
  /// In en, this message translates to:
  /// **'A secret/service-role key was supplied. Only the publishable key may be used in the app.'**
  String get configErrorSecretKey;

  /// No description provided for @errorInvalidData.
  ///
  /// In en, this message translates to:
  /// **'We received data we couldn\'t read. Please try again later.'**
  String get errorInvalidData;

  /// No description provided for @destinationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No destinations yet'**
  String get destinationsEmptyTitle;

  /// No description provided for @destinationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The catalog is empty right now. Check back soon.'**
  String get destinationsEmptyBody;

  /// No description provided for @destinationsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load destinations'**
  String get destinationsErrorTitle;

  /// No description provided for @destinationFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get destinationFeatured;

  /// No description provided for @destinationFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String destinationFromPrice(String price);

  /// No description provided for @destinationPerPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get destinationPerPerson;

  /// No description provided for @destinationNoPackages.
  ///
  /// In en, this message translates to:
  /// **'No packages available yet'**
  String get destinationNoPackages;

  /// No description provided for @destinationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String destinationDays(int count);

  /// No description provided for @destinationDaysRange.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} days'**
  String destinationDaysRange(int min, int max);

  /// No description provided for @destinationImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get destinationImageUnavailable;

  /// No description provided for @accountBrowseDestinations.
  ///
  /// In en, this message translates to:
  /// **'Browse destinations'**
  String get accountBrowseDestinations;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile details.'**
  String get profileLoadError;

  /// No description provided for @detailsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get detailsAbout;

  /// No description provided for @detailsBestSeason.
  ///
  /// In en, this message translates to:
  /// **'Best time to visit'**
  String get detailsBestSeason;

  /// No description provided for @detailsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get detailsCoordinates;

  /// No description provided for @detailsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get detailsGallery;

  /// No description provided for @detailsGalleryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {total}'**
  String detailsGalleryPhoto(int index, int total);

  /// No description provided for @detailsPhotoCredit.
  ///
  /// In en, this message translates to:
  /// **'Photos: {credit}'**
  String detailsPhotoCredit(String credit);

  /// No description provided for @detailsPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get detailsPackagesTitle;

  /// No description provided for @detailsPackagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No packages are available for this destination right now.'**
  String get detailsPackagesEmpty;

  /// No description provided for @detailsPackagesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load packages.'**
  String get detailsPackagesError;

  /// No description provided for @detailsNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Destination not found'**
  String get detailsNotFoundTitle;

  /// No description provided for @detailsNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may no longer be available, or the link is incorrect.'**
  String get detailsNotFoundBody;

  /// No description provided for @detailsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this destination'**
  String get detailsErrorTitle;

  /// No description provided for @detailsBackToDestinations.
  ///
  /// In en, this message translates to:
  /// **'Back to destinations'**
  String get detailsBackToDestinations;

  /// No description provided for @detailsPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Sample prices per person. No payment is taken in this app.'**
  String get detailsPriceNote;

  /// No description provided for @packageIncludes.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get packageIncludes;

  /// No description provided for @packageMaxTravelers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Up to 1 traveller} other{Up to {count} travellers}}'**
  String packageMaxTravelers(int count);

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any destination to save it here.'**
  String get favoritesEmptyBody;

  /// No description provided for @favoritesErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your favourites'**
  String get favoritesErrorTitle;

  /// No description provided for @favoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get favoriteRemove;

  /// No description provided for @favoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Saved to favourites'**
  String get favoriteAdded;

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get favoriteRemoved;

  /// No description provided for @favoriteAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save to favourites. {reason}'**
  String favoriteAddFailed(String reason);

  /// No description provided for @favoriteRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove from favourites. {reason}'**
  String favoriteRemoveFailed(String reason);

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Some of the details you entered aren\'t valid. Please check them and try again.'**
  String get errorInvalidInput;

  /// No description provided for @bookingErrorPackageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This package is no longer available. Please choose another one.'**
  String get bookingErrorPackageUnavailable;

  /// No description provided for @bookingErrorTooManyTravelers.
  ///
  /// In en, this message translates to:
  /// **'This package doesn\'t allow that many travellers.'**
  String get bookingErrorTooManyTravelers;

  /// No description provided for @bookingErrorInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Please choose a travel date between tomorrow and one year from now.'**
  String get bookingErrorInvalidDate;

  /// No description provided for @bookingErrorNotCancellable.
  ///
  /// In en, this message translates to:
  /// **'This booking can no longer be cancelled.'**
  String get bookingErrorNotCancellable;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number (digits, spaces, + ( ) -)'**
  String get validationPhoneInvalid;

  /// No description provided for @validationTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters'**
  String validationTextTooLong(int max);

  /// No description provided for @packageBookCta.
  ///
  /// In en, this message translates to:
  /// **'Book this package'**
  String get packageBookCta;

  /// No description provided for @bookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Book your trip'**
  String get bookingTitle;

  /// No description provided for @bookingPackageLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get bookingPackageLabel;

  /// No description provided for @bookingPackageRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a package'**
  String get bookingPackageRequired;

  /// No description provided for @bookingNoPackages.
  ///
  /// In en, this message translates to:
  /// **'This destination has no bookable packages right now.'**
  String get bookingNoPackages;

  /// No description provided for @bookingLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load booking options'**
  String get bookingLoadErrorTitle;

  /// No description provided for @bookingTravelDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Travel date'**
  String get bookingTravelDateLabel;

  /// No description provided for @bookingTravelDatePick.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get bookingTravelDatePick;

  /// No description provided for @bookingTravelDateHint.
  ///
  /// In en, this message translates to:
  /// **'You can book from tomorrow up to one year ahead.'**
  String get bookingTravelDateHint;

  /// No description provided for @bookingTravelDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a travel date'**
  String get bookingTravelDateRequired;

  /// No description provided for @bookingTravelersLabel.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get bookingTravelersLabel;

  /// No description provided for @bookingTravelersMax.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This package is for 1 traveller.} other{This package allows up to {count} travellers.}}'**
  String bookingTravelersMax(int count);

  /// No description provided for @bookingTravelersDecrease.
  ///
  /// In en, this message translates to:
  /// **'Fewer travellers'**
  String get bookingTravelersDecrease;

  /// No description provided for @bookingTravelersIncrease.
  ///
  /// In en, this message translates to:
  /// **'More travellers'**
  String get bookingTravelersIncrease;

  /// No description provided for @bookingTravelersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 traveller} other{{count} travellers}}'**
  String bookingTravelersCount(int count);

  /// No description provided for @bookingContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get bookingContactSection;

  /// No description provided for @bookingContactName.
  ///
  /// In en, this message translates to:
  /// **'Lead traveller\'s full name'**
  String get bookingContactName;

  /// No description provided for @bookingContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get bookingContactPhone;

  /// No description provided for @bookingContactPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+20 100 000 0000'**
  String get bookingContactPhoneHint;

  /// No description provided for @bookingSpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special requests (optional)'**
  String get bookingSpecialRequests;

  /// No description provided for @bookingSpecialRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Dietary needs, accessibility, room preferences…'**
  String get bookingSpecialRequestsHint;

  /// No description provided for @bookingContinueToReview.
  ///
  /// In en, this message translates to:
  /// **'Review booking'**
  String get bookingContinueToReview;

  /// No description provided for @bookingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your booking'**
  String get bookingReviewTitle;

  /// No description provided for @bookingReviewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get bookingReviewEdit;

  /// No description provided for @bookingPricePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Price per person'**
  String get bookingPricePerPerson;

  /// No description provided for @bookingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// No description provided for @bookingTotalNote.
  ///
  /// In en, this message translates to:
  /// **'The final amount is calculated by our server from the package price when you confirm.'**
  String get bookingTotalNote;

  /// No description provided for @bookingNoPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'No payment is taken in this app, and availability isn\'t checked in real time. Confirming records your reservation.'**
  String get bookingNoPaymentNote;

  /// No description provided for @bookingConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get bookingConfirmCta;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Your reservation has been recorded. Keep your reference for any questions.'**
  String get bookingConfirmedBody;

  /// No description provided for @bookingReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get bookingReference;

  /// No description provided for @bookingViewMyBookings.
  ///
  /// In en, this message translates to:
  /// **'View my bookings'**
  String get bookingViewMyBookings;

  /// No description provided for @bookingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bookingDone;

  /// No description provided for @myBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookingsTitle;

  /// No description provided for @myBookingsFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get myBookingsFilterUpcoming;

  /// No description provided for @myBookingsFilterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get myBookingsFilterPast;

  /// No description provided for @myBookingsFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get myBookingsFilterCancelled;

  /// No description provided for @myBookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get myBookingsEmptyTitle;

  /// No description provided for @myBookingsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you book a trip, it will appear here.'**
  String get myBookingsEmptyBody;

  /// No description provided for @myBookingsNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'You have no upcoming trips.'**
  String get myBookingsNoUpcoming;

  /// No description provided for @myBookingsNoPast.
  ///
  /// In en, this message translates to:
  /// **'You have no past trips.'**
  String get myBookingsNoPast;

  /// No description provided for @myBookingsNoCancelled.
  ///
  /// In en, this message translates to:
  /// **'You have no cancelled bookings.'**
  String get myBookingsNoCancelled;

  /// No description provided for @myBookingsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your bookings'**
  String get myBookingsErrorTitle;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingPastTrip.
  ///
  /// In en, this message translates to:
  /// **'Past trip'**
  String get bookingPastTrip;

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetailsTitle;

  /// No description provided for @bookingBookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked on {date}'**
  String bookingBookedOn(String date);

  /// No description provided for @bookingCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on {date}'**
  String bookingCancelledOn(String date);

  /// No description provided for @bookingContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get bookingContact;

  /// No description provided for @bookingCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get bookingCancelCta;

  /// No description provided for @bookingCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get bookingCancelConfirmTitle;

  /// No description provided for @bookingCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Your reservation for {destination} on {date} will be cancelled.'**
  String bookingCancelConfirmBody(String destination, String date);

  /// No description provided for @bookingCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get bookingCancelKeep;

  /// No description provided for @bookingCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelledToast;

  /// No description provided for @bookingCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel the booking. {reason}'**
  String bookingCancelFailed(String reason);

  /// No description provided for @bookingCancelPolicy.
  ///
  /// In en, this message translates to:
  /// **'Bookings can be cancelled until the day before travel.'**
  String get bookingCancelPolicy;

  /// No description provided for @bookingCatalogItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No longer listed in the catalog'**
  String get bookingCatalogItemUnavailable;

  /// No description provided for @bookingNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking not found'**
  String get bookingNotFoundTitle;

  /// No description provided for @bookingNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may belong to another account, or the link is incorrect.'**
  String get bookingNotFoundBody;

  /// No description provided for @bookingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this booking'**
  String get bookingErrorTitle;

  /// No description provided for @bookingErrorIdempotencyConflict.
  ///
  /// In en, this message translates to:
  /// **'This booking request matches an earlier one with different details. Check My bookings, then try again.'**
  String get bookingErrorIdempotencyConflict;

  /// No description provided for @accountNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountNotifications;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you book or cancel a trip, the update will appear here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notifications'**
  String get notificationsErrorTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update notifications. {error}'**
  String notificationsActionFailed(String error);

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread notifications} =1{1 unread notification} other{{count} unread notifications}}'**
  String notificationsUnreadCount(int count);

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// No description provided for @notificationBookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get notificationBookingConfirmedTitle;

  /// No description provided for @notificationBookingCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get notificationBookingCancelledTitle;

  /// No description provided for @notificationTripReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip reminder'**
  String get notificationTripReminderTitle;

  /// No description provided for @notificationTripOn.
  ///
  /// In en, this message translates to:
  /// **'{destination} on {date}'**
  String notificationTripOn(String destination, String date);

  /// No description provided for @notificationReference.
  ///
  /// In en, this message translates to:
  /// **'Ref. {reference}'**
  String notificationReference(String reference);

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsTripReminders.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders'**
  String get settingsTripReminders;

  /// No description provided for @settingsTripRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On this device, at 9:00 the day before each confirmed trip'**
  String get settingsTripRemindersSubtitle;

  /// No description provided for @settingsNotificationsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders and push notifications aren\'t available on this platform.'**
  String get settingsNotificationsUnsupported;

  /// No description provided for @settingsNotificationsAllowHint.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so trip reminders can appear.'**
  String get settingsNotificationsAllowHint;

  /// No description provided for @settingsNotificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsNotificationsAllow;

  /// No description provided for @settingsNotificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Rahala in your device settings.'**
  String get settingsNotificationsBlocked;

  /// No description provided for @settingsNotificationsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsNotificationsOpenSettings;

  /// No description provided for @notificationsPermissionDeniedToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications weren\'t allowed. You can turn them on later in your device settings.'**
  String get notificationsPermissionDeniedToast;

  /// No description provided for @tripReminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders'**
  String get tripReminderChannelName;

  /// No description provided for @tripReminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders the day before your booked trips'**
  String get tripReminderChannelDescription;

  /// No description provided for @tripReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your trip to {destination} is tomorrow'**
  String tripReminderTitle(String destination);

  /// No description provided for @tripReminderTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your trip is tomorrow'**
  String get tripReminderTitleGeneric;

  /// No description provided for @tripReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{package} · {date} · Ref. {reference}'**
  String tripReminderBody(String package, String date, String reference);

  /// No description provided for @tripReminderBodyNoPackage.
  ///
  /// In en, this message translates to:
  /// **'{date} · Ref. {reference}'**
  String tripReminderBodyNoPackage(String date, String reference);

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @pushForegroundBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get pushForegroundBookingConfirmed;

  /// No description provided for @pushForegroundBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get pushForegroundBookingCancelled;

  /// No description provided for @bookingUpdatesChannelName.
  ///
  /// In en, this message translates to:
  /// **'Booking updates'**
  String get bookingUpdatesChannelName;

  /// No description provided for @bookingUpdatesChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirmations and cancellations of your bookings'**
  String get bookingUpdatesChannelDescription;

  /// No description provided for @settingsPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking updates'**
  String get settingsPushTitle;

  /// No description provided for @settingsPushOn.
  ///
  /// In en, this message translates to:
  /// **'Confirmations and cancellations are sent to this device.'**
  String get settingsPushOn;

  /// No description provided for @settingsPushNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to get booking updates on this device.'**
  String get settingsPushNeedsPermission;

  /// No description provided for @settingsPushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Push notifications aren\'t set up for this device yet.'**
  String get settingsPushUnavailable;

  /// No description provided for @settingsPushNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This device isn\'t registered for booking updates yet. Rahala will retry when you reopen the app.'**
  String get settingsPushNotRegistered;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreetingName(String greeting, String name);

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Where to next?'**
  String get homeHeadline;

  /// No description provided for @homeNotificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Notifications, 1 unread} other{Notifications, {count} unread}}'**
  String homeNotificationsUnread(int count);

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations or countries'**
  String get homeSearchHint;

  /// No description provided for @homeNextTrip.
  ///
  /// In en, this message translates to:
  /// **'Your next trip'**
  String get homeNextTrip;

  /// No description provided for @homeSeeAllTrips.
  ///
  /// In en, this message translates to:
  /// **'All trips'**
  String get homeSeeAllTrips;

  /// No description provided for @homeTripToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTripToday;

  /// No description provided for @homeTripTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeTripTomorrow;

  /// No description provided for @homeTripInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{In 1 day} other{In {days} days}}'**
  String homeTripInDays(int days);

  /// No description provided for @homeTripsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your trips.'**
  String get homeTripsError;

  /// No description provided for @homeNoTripTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips'**
  String get homeNoTripTitle;

  /// No description provided for @homeNoTripBody.
  ///
  /// In en, this message translates to:
  /// **'Your next adventure starts with a destination.'**
  String get homeNoTripBody;

  /// No description provided for @homeNoTripCta.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeNoTripCta;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse by type'**
  String get homeCategories;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured destinations'**
  String get homeFeatured;

  /// No description provided for @homeFeaturedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hand-picked from the Rahala catalog'**
  String get homeFeaturedSubtitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeRecentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get homeRecentlyViewed;

  /// No description provided for @homeSavedShortcut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved destination} other{{count} saved destinations}}'**
  String homeSavedShortcut(int count);

  /// No description provided for @homeMoreToExplore.
  ///
  /// In en, this message translates to:
  /// **'More to explore'**
  String get homeMoreToExplore;

  /// No description provided for @homeMoreToExploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every other destination in the catalog'**
  String get homeMoreToExploreSubtitle;

  /// No description provided for @homeCatalogError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load destinations.'**
  String get homeCatalogError;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Destination, country or experience'**
  String get exploreSearchHint;

  /// No description provided for @exploreClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get exploreClearSearch;

  /// No description provided for @exploreFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get exploreFilters;

  /// No description provided for @exploreAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exploreAllCategories;

  /// No description provided for @exploreResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 destination} other{{count} destinations}}'**
  String exploreResultCount(int count);

  /// No description provided for @exploreSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get exploreSort;

  /// No description provided for @exploreSortFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured first'**
  String get exploreSortFeatured;

  /// No description provided for @exploreSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get exploreSortPriceLow;

  /// No description provided for @exploreSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get exploreSortPriceHigh;

  /// No description provided for @exploreSortName.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get exploreSortName;

  /// No description provided for @exploreNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching destinations'**
  String get exploreNoResultsTitle;

  /// No description provided for @exploreNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”. Try another name or country, or clear the filters.'**
  String exploreNoResultsBody(String query);

  /// No description provided for @exploreNoResultsFiltersBody.
  ///
  /// In en, this message translates to:
  /// **'No destination fits these filters. Try widening them.'**
  String get exploreNoResultsFiltersBody;

  /// No description provided for @exploreClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear search & filters'**
  String get exploreClearAll;

  /// No description provided for @exploreMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Starting price per person'**
  String get exploreMaxPrice;

  /// No description provided for @exploreAnyPrice.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get exploreAnyPrice;

  /// No description provided for @explorePriceUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {price}'**
  String explorePriceUpTo(String price);

  /// No description provided for @explorePriceNote.
  ///
  /// In en, this message translates to:
  /// **'Based on each destination\'s cheapest package. Prices are sample catalog prices.'**
  String get explorePriceNote;

  /// No description provided for @exploreTripLength.
  ///
  /// In en, this message translates to:
  /// **'Trip length'**
  String get exploreTripLength;

  /// No description provided for @exploreLengthShort.
  ///
  /// In en, this message translates to:
  /// **'Short break (1–3 days)'**
  String get exploreLengthShort;

  /// No description provided for @exploreLengthMedium.
  ///
  /// In en, this message translates to:
  /// **'4–6 days'**
  String get exploreLengthMedium;

  /// No description provided for @exploreLengthLong.
  ///
  /// In en, this message translates to:
  /// **'A week or more'**
  String get exploreLengthLong;

  /// No description provided for @exploreReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get exploreReset;

  /// No description provided for @exploreApply.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get exploreApply;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile.'**
  String get profileSaveFailed;

  /// No description provided for @profileDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get profileDiscardTitle;

  /// No description provided for @profileDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits haven\'t been saved.'**
  String get profileDiscardBody;

  /// No description provided for @profileDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get profileDiscard;

  /// No description provided for @profileKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get profileKeepEditing;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get profilePhoneLabel;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +20 100 000 0000'**
  String get profilePhoneHint;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in email can\'t be changed here.'**
  String get profileEmailReadOnly;

  /// No description provided for @profileStatsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your trip statistics.'**
  String get profileStatsError;

  /// No description provided for @profilePhotoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your photo.'**
  String get profilePhotoFailed;

  /// No description provided for @profilePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large (max 2 MB). Try another one.'**
  String get profilePhotoTooLarge;

  /// No description provided for @profilePhotoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the photo picker. Check the app\'s permissions.'**
  String get profilePhotoPickFailed;

  /// No description provided for @levelTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveler level'**
  String get levelTitle;

  /// No description provided for @levelNewTraveler.
  ///
  /// In en, this message translates to:
  /// **'New traveler'**
  String get levelNewTraveler;

  /// No description provided for @levelExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get levelExplorer;

  /// No description provided for @levelVoyager.
  ///
  /// In en, this message translates to:
  /// **'Voyager'**
  String get levelVoyager;

  /// No description provided for @levelGlobetrotter.
  ///
  /// In en, this message translates to:
  /// **'Globetrotter'**
  String get levelGlobetrotter;

  /// No description provided for @levelHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How levels work'**
  String get levelHowItWorks;

  /// No description provided for @levelProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress to the next level'**
  String get levelProgress;

  /// No description provided for @levelTopReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the top level. Happy travels!'**
  String get levelTopReached;

  /// No description provided for @levelNextHint.
  ///
  /// In en, this message translates to:
  /// **'{missing} to become {level}.'**
  String levelNextHint(String missing, String level);

  /// No description provided for @levelTripsMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more completed trip} other{{count} more completed trips}}'**
  String levelTripsMore(int count);

  /// No description provided for @levelCountriesMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more country} other{{count} more countries}}'**
  String levelCountriesMore(int count);

  /// No description provided for @levelRulesIntro.
  ///
  /// In en, this message translates to:
  /// **'Your level comes only from trips you have actually taken with Rahala: confirmed bookings whose travel date has passed. Cancelled bookings don\'t count.'**
  String get levelRulesIntro;

  /// No description provided for @levelRuleStart.
  ///
  /// In en, this message translates to:
  /// **'Where everyone starts'**
  String get levelRuleStart;

  /// No description provided for @levelRule.
  ///
  /// In en, this message translates to:
  /// **'{trips} in {countries}'**
  String levelRule(String trips, String countries);

  /// No description provided for @levelTripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed trip} other{{count} completed trips}}'**
  String levelTripsCount(int count);

  /// No description provided for @levelCountriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 country} other{{count} different countries}}'**
  String levelCountriesCount(int count);

  /// No description provided for @levelRulesNote.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a rating from other people — Rahala has no reviews. It simply reflects your own travel history.'**
  String get levelRulesNote;

  /// No description provided for @statsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trips taken'**
  String get statsCompleted;

  /// No description provided for @statsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statsUpcoming;

  /// No description provided for @statsDestinations.
  ///
  /// In en, this message translates to:
  /// **'Destinations visited'**
  String get statsDestinations;

  /// No description provided for @statsCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries visited'**
  String get statsCountries;

  /// No description provided for @statsFootnote.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Based on your 1 booking} other{Based on your {total} bookings}} · {cancelled, plural, =0{none cancelled} =1{1 cancelled} other{{cancelled} cancelled}}'**
  String statsFootnote(int total, int cancelled);

  /// No description provided for @statsNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet — your statistics will appear after your first trip.'**
  String get statsNoBookings;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather now'**
  String get weatherTitle;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather is unavailable right now.'**
  String get weatherUnavailable;

  /// No description provided for @weatherSource.
  ///
  /// In en, this message translates to:
  /// **'Live weather at the destination · data by Open-Meteo.com'**
  String get weatherSource;

  /// No description provided for @weatherDegrees.
  ///
  /// In en, this message translates to:
  /// **'{value}°C'**
  String weatherDegrees(int value);

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherShowers.
  ///
  /// In en, this message translates to:
  /// **'Showers'**
  String get weatherShowers;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherUnknown.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherUnknown;

  /// No description provided for @detailsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get detailsShare;

  /// No description provided for @detailsShareText.
  ///
  /// In en, this message translates to:
  /// **'{name}, {country} — {summary}\nOpen in Rahala: {link}'**
  String detailsShareText(String name, String country, String summary, String link);

  /// No description provided for @detailsShareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing isn\'t available on this device.'**
  String get detailsShareUnavailable;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, photo, bookings, saved destinations and notifications from Rahala. It can\'t be undone.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteConfirmCheck.
  ///
  /// In en, this message translates to:
  /// **'I understand this can\'t be undone'**
  String get accountDeleteConfirmCheck;

  /// No description provided for @accountDeleteCta.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get accountDeleteCta;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. {reason}'**
  String accountDeleteFailed(String reason);

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountChangePassword;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change your password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account. You\'ll stay signed in on this device.'**
  String get changePasswordSubtitle;

  /// No description provided for @bookingErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'ve made several bookings in the last hour. Please try again later.'**
  String get bookingErrorRateLimited;

  /// No description provided for @bookingViewDestination.
  ///
  /// In en, this message translates to:
  /// **'View destination'**
  String get bookingViewDestination;

  /// No description provided for @favoritesRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh your saved destinations. {reason}'**
  String favoritesRefreshFailed(String reason);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError('AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
