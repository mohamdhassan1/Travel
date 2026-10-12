import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/app/app.dart';
import 'package:rahala/data/repositories/app_preferences.dart';
import 'package:rahala/data/repositories/booking_request_id_store.dart';
import 'package:rahala/data/repositories/recently_viewed_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_account_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_booking_repository.dart';
import 'fake_data_repositories.dart';
import 'fake_device_notifications.dart';
import 'fake_notifications_repository.dart';
import 'fake_phase8.dart';

/// Pumps the full app (router, cubits, theme, l10n) against a fake backend.
Future<FakeAuthRepository> pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? repo,
  FakeCatalogRepository? catalog,
  FakeProfileRepository? profile,
  FakeFavoritesRepository? favorites,
  FakeBookingRepository? bookings,
  FakeNotificationsRepository? notifications,
  FakeLocalReminderNotifier? localNotifier,
  FakePushMessaging? push,
  FakeDeviceTokenRepository? deviceTokens,
  FakeWeatherRepository? weather,
  FakePhotoPicker? photoPicker,
  FakeShareService? share,
  FakeAccountRepository? account,
  Map<String, Object> prefs = const {
    'onboarding.completed': true,
    'settings.locale': 'en',
  },
  String? initialLocation,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final preferences = AppPreferences(sharedPrefs);
  final auth = repo ?? FakeAuthRepository();
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    RahalaApp(
      authRepository: auth,
      catalogRepository: catalog ?? FakeCatalogRepository(),
      profileRepository: profile ?? FakeProfileRepository(),
      favoritesRepository: favorites ?? FakeFavoritesRepository(currentUserId: () => auth.currentUser?.id),
      bookingRepository: bookings ?? FakeBookingRepository(currentUserId: () => auth.currentUser?.id),
      notificationsRepository: notifications ?? FakeNotificationsRepository(currentUserId: () => auth.currentUser?.id),
      bookingRequestIds: BookingRequestIdStore(sharedPrefs),
      // Off unless a test opts in, like a platform without notifications.
      localNotifier: localNotifier ?? FakeLocalReminderNotifier(supported: false),
      pushMessaging: push ?? FakePushMessaging(available: false),
      deviceTokenRepository: deviceTokens ?? FakeDeviceTokenRepository(currentUserId: () => auth.currentUser?.id),
      preferences: preferences,
      weatherRepository: weather ?? FakeWeatherRepository(),
      photoPicker: photoPicker ?? FakePhotoPicker(),
      recentlyViewedStore: RecentlyViewedStore(sharedPrefs),
      shareService: share ?? FakeShareService(),
      accountRepository: account ?? FakeAccountRepository(),
      useGoogleFonts: false,
      initialLocation: initialLocation,
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

Finder field(String label) => find.widgetWithText(TextFormField, label);
