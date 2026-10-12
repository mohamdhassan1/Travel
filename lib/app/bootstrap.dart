import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';
import '../data/media/photo_picker.dart';
import '../data/media/share_service.dart';
import '../data/notifications/local_reminder_notifier.dart';
import '../data/notifications/push_messaging.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/app_preferences.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/booking_request_id_store.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/device_token_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/recently_viewed_store.dart';
import '../data/repositories/supabase_auth_repository.dart';
import '../data/repositories/weather_repository.dart';
import 'app.dart';
import 'configuration_error_app.dart';

/// Startup: validate configuration, restore the Supabase session, then run.
/// Kept minimal so the first frame appears quickly.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  final config = AppConfig.fromEnvironment();
  final issue = config.validate();
  if (issue != null) {
    runApp(ConfigurationErrorApp(issue: issue));
    return;
  }

  final (prefs, _) = await (
    SharedPreferences.getInstance(),
    Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      // PKCE is the default auth flow for mobile deep-link callbacks.
    ),
  ).wait;

  // Optional device notifications: Firebase (FCM) and local trip reminders.
  // Each returns false instead of failing; the app runs without them.
  final pushMessaging = FirebasePushMessaging();
  final localNotifier = FlutterLocalReminderNotifier();
  await (
    pushMessaging.initialize().timeout(const Duration(seconds: 8), onTimeout: () => false),
    localNotifier.initialize().timeout(const Duration(seconds: 8), onTimeout: () => false),
  ).wait;

  final client = Supabase.instance.client;
  runApp(
    RahalaApp(
      authRepository: SupabaseAuthRepository(
        client.auth,
        redirectUrl: AppConfig.authRedirectUrl,
      ),
      catalogRepository: SupabaseCatalogRepository(client),
      profileRepository: SupabaseProfileRepository(client),
      favoritesRepository: SupabaseFavoritesRepository(client, currentUserId: () => client.auth.currentUser?.id),
      notificationsRepository:
          SupabaseNotificationsRepository(client, currentUserId: () => client.auth.currentUser?.id),
      bookingRepository: SupabaseBookingRepository(client, currentUserId: () => client.auth.currentUser?.id),
      bookingRequestIds: BookingRequestIdStore(prefs),
      localNotifier: localNotifier,
      pushMessaging: pushMessaging,
      deviceTokenRepository: SupabaseDeviceTokenRepository(client, currentUserId: () => client.auth.currentUser?.id),
      preferences: AppPreferences(prefs),
      weatherRepository: OpenMeteoWeatherRepository(),
      // Web: browsers offer a file chooser; there is no in-app camera capture.
      photoPicker: ImagePickerPhotoPicker(canUseCamera: !kIsWeb),
      recentlyViewedStore: RecentlyViewedStore(prefs),
      shareService: SharePlusShareService(),
      accountRepository: SupabaseAccountRepository(client),
    ),
  );
}
