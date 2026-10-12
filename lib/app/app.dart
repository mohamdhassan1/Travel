import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/media/photo_picker.dart';
import '../data/media/share_service.dart';
import '../data/notifications/local_reminder_notifier.dart';
import '../data/notifications/push_messaging.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/app_preferences.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/booking_request_id_store.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/device_token_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/recently_viewed_store.dart';
import '../data/repositories/weather_repository.dart';
import '../l10n/app_localizations.dart';
import '../logic/auth/session_cubit.dart';
import '../logic/booking/my_bookings_cubit.dart';
import '../logic/booking/observable_booking_repository.dart';
import '../logic/catalog/catalog_cubit.dart';
import '../logic/catalog/recently_viewed_cubit.dart';
import '../logic/favorites/favorites_cubit.dart';
import '../logic/notifications/device_notifications_cubit.dart';
import '../logic/notifications/notifications_cubit.dart';
import '../logic/notifications/push_token_sync.dart';
import '../logic/notifications/reminder_syncing_booking_repository.dart';
import '../logic/notifications/trip_reminder_scheduler.dart';
import '../logic/profile/profile_cubit.dart';
import '../logic/settings/settings_cubit.dart';
import '../presentation/favorites/widgets/favorite_feedback_listener.dart';
import '../presentation/profile/widgets/profile_photo_actions.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

/// Composition root: wires repositories, app-wide cubits, theme,
/// localization and the router.
class RahalaApp extends StatefulWidget {
  const RahalaApp({
    super.key,
    required this.authRepository,
    required this.catalogRepository,
    required this.profileRepository,
    required this.favoritesRepository,
    required this.notificationsRepository,
    required this.bookingRepository,
    required this.bookingRequestIds,
    required this.localNotifier,
    required this.pushMessaging,
    required this.deviceTokenRepository,
    required this.preferences,
    required this.weatherRepository,
    required this.photoPicker,
    required this.recentlyViewedStore,
    required this.shareService,
    required this.accountRepository,
    this.useGoogleFonts = true,
    this.initialLocation,
  });

  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final ProfileRepository profileRepository;
  final FavoritesRepository favoritesRepository;
  final NotificationsRepository notificationsRepository;
  final BookingRepository bookingRepository;
  final BookingRequestIdStore bookingRequestIds;
  final LocalReminderNotifier localNotifier;
  final PushMessaging pushMessaging;
  final DeviceTokenRepository deviceTokenRepository;
  final AppPreferences preferences;
  final WeatherRepository weatherRepository;
  final PhotoPicker photoPicker;
  final RecentlyViewedStore recentlyViewedStore;
  final ShareService shareService;
  final AccountRepository accountRepository;

  /// Disabled in tests (no network access to fetch fonts).
  final bool useGoogleFonts;
  final String? initialLocation;

  @override
  State<RahalaApp> createState() => _RahalaAppState();
}

class _RahalaAppState extends State<RahalaApp> {
  late final SessionCubit _session = SessionCubit(widget.authRepository);
  late final SettingsCubit _settings = SettingsCubit(widget.preferences);

  /// App-scoped so every screen shares one view of the user's favourites;
  /// it follows the session and clears itself on sign-out.
  late final FavoritesCubit _favorites = FavoritesCubit(widget.favoritesRepository, _session);

  /// App-scoped for the Account badge and the Notifications screen; follows
  /// the session like favourites.
  late final NotificationsCubit _notifications = NotificationsCubit(widget.notificationsRepository, _session);

  String? _currentUserId() => widget.authRepository.currentUser?.id;

  /// Local trip reminders, scheduled from booking results (see
  /// [ReminderSyncingBookingRepository]).
  late final TripReminderScheduler _reminders = TripReminderScheduler(
    widget.localNotifier,
    enabled: () => widget.preferences.tripRemindersEnabled,
    locale: () => _resolveLocale(_settings.state.locale),
  );

  /// Booking calls: reminders follow server results, and create/cancel are
  /// announced so app-wide views (Home, Trips, Profile stats) refresh.
  late final ObservableBookingRepository _bookings = ObservableBookingRepository(
    ReminderSyncingBookingRepository(widget.bookingRepository, _reminders, currentUserId: _currentUserId),
  );

  /// Shared, app-wide views (one request each, reused by every tab).
  late final CatalogCubit _catalog = CatalogCubit(widget.catalogRepository);
  late final MyBookingsCubit _myBookings = MyBookingsCubit(_bookings, _session, changes: _bookings.changes);
  late final ProfileCubit _profile = ProfileCubit(widget.profileRepository, _session);
  late final RecentlyViewedCubit _recent = RecentlyViewedCubit(widget.recentlyViewedStore, _session);

  /// Device-side notifications (reminders + FCM token), separate from the
  /// server notifications above.
  late final DeviceNotificationsCubit _deviceNotifications = DeviceNotificationsCubit(
    notifier: widget.localNotifier,
    push: widget.pushMessaging,
    tokenSync: PushTokenSync(widget.pushMessaging, widget.deviceTokenRepository),
    reminders: _reminders,
    bookings: _bookings,
    session: _session,
    preferences: widget.preferences,
    locale: () => _resolveLocale(_settings.state.locale),
  );
  final _subscriptions = <StreamSubscription<Object?>>[];
  late final AppLifecycleListener _lifecycle;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router = widget.initialLocation == null
      ? createAppRouter(session: _session, settings: _settings)
      : createAppRouter(
          session: _session,
          settings: _settings,
          initialLocation: widget.initialLocation!,
        );

  @override
  void initState() {
    super.initState();
    _subscriptions
      // A tapped reminder / push opens the booking (the route is protected:
      // signed out, it goes through login and back).
      ..add(_deviceNotifications.openBookingRequests.listen((id) => _router.go(AppRoutes.booking(id))))
      ..add(_deviceNotifications.foregroundPushes.listen(_onForegroundPush))
      // A booking created or cancelled here: the database wrote its
      // notification in the same transaction, so the bell/badge refreshes
      // now instead of waiting for a push (web, no permission) or a pull.
      ..add(_bookings.changes.listen((_) => _notifications.refresh()))
      ..add(_settings.stream.map((s) => s.locale).distinct().listen((_) => _deviceNotifications.languageChanged()));
    _lifecycle = AppLifecycleListener(onResume: _deviceNotifications.refreshPermission);
    _deviceNotifications.start();
    _catalog.load();
    _myBookings.load();
  }

  /// A remote push while the app is open: refresh the server notifications
  /// (badge + list) and show a single in-app message instead of a system
  /// banner, so the same event is never shown twice.
  void _onForegroundPush(PushMessage message) {
    _notifications.refresh();
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    // The messenger sits above Localizations, so resolve strings directly.
    final l10n = lookupAppLocalizations(_resolveLocale(_settings.state.locale));
    final text = message.isBookingConfirmed
        ? l10n.pushForegroundBookingConfirmed
        : message.isBookingCancelled
            ? l10n.pushForegroundBookingCancelled
            : null;
    if (text == null) return;
    final bookingId = message.bookingId;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message.reference == null ? text : '$text · ${message.reference}'),
        action: bookingId != null && isUuid(bookingId)
            ? SnackBarAction(label: l10n.commonView, onPressed: () => _router.go(AppRoutes.booking(bookingId)))
            : null,
      ));
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _lifecycle.dispose();
    _router.dispose();
    _deviceNotifications.close();
    _favorites.close();
    _catalog.close();
    _myBookings.close();
    _profile.close();
    _recent.close();
    _bookings.dispose();
    _notifications.close();
    _session.close();
    _settings.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.authRepository),
        RepositoryProvider<CatalogRepository>.value(
          value: widget.catalogRepository,
        ),
        RepositoryProvider<ProfileRepository>.value(
          value: widget.profileRepository,
        ),
        RepositoryProvider<FavoritesRepository>.value(value: widget.favoritesRepository),
        RepositoryProvider<NotificationsRepository>.value(value: widget.notificationsRepository),
        RepositoryProvider<BookingRepository>.value(value: _bookings),
        RepositoryProvider<BookingRequestIdStore>.value(value: widget.bookingRequestIds),
        RepositoryProvider<AppPreferences>.value(value: widget.preferences),
        RepositoryProvider<WeatherRepository>.value(value: widget.weatherRepository),
        RepositoryProvider<PhotoPicker>.value(value: widget.photoPicker),
        RepositoryProvider<ShareService>.value(value: widget.shareService),
        RepositoryProvider<AccountRepository>.value(value: widget.accountRepository),
        RepositoryProvider<RecentlyViewedStore>.value(value: widget.recentlyViewedStore),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _session),
          BlocProvider.value(value: _settings),
          BlocProvider.value(value: _favorites),
          BlocProvider.value(value: _notifications),
          BlocProvider.value(value: _deviceNotifications),
          BlocProvider.value(value: _catalog),
          BlocProvider.value(value: _myBookings),
          BlocProvider.value(value: _profile),
          BlocProvider.value(value: _recent),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (a, b) => a.themeMode != b.themeMode || a.locale != b.locale,
          builder: (context, settings) {
            final locale = _resolveLocale(settings.locale);
            return MaterialApp.router(
              onGenerateTitle: (context) => AppLocalizations.of(context).appName,
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              scaffoldMessengerKey: _messengerKey,
              builder: (context, child) => FavoriteFeedbackListener(
                messengerKey: _messengerKey,
                child: ProfileEventListener(messengerKey: _messengerKey, child: child ?? const SizedBox.shrink()),
              ),
              locale: settings.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: settings.themeMode,
              theme: AppTheme.light(
                locale,
                useGoogleFonts: widget.useGoogleFonts,
              ),
              darkTheme: AppTheme.dark(
                locale,
                useGoogleFonts: widget.useGoogleFonts,
              ),
            );
          },
        ),
      ),
    );
  }

  /// The locale used for typography: explicit choice, else the device's
  /// language if supported, else English.
  Locale _resolveLocale(Locale? chosen) {
    if (chosen != null) return chosen;
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == device.languageCode,
    )
        ? Locale(device.languageCode)
        : const Locale('en');
  }
}
