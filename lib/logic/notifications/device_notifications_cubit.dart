import 'dart:async';

import 'dart:ui' show Locale;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_logger.dart';
import '../../data/notifications/local_reminder_notifier.dart';
import '../../data/notifications/push_messaging.dart';
import '../../data/repositories/app_preferences.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/catalog_repository.dart' show isUuid;
import '../../l10n/app_localizations.dart';
import '../auth/session_cubit.dart';
import 'push_token_sync.dart';
import 'trip_reminder_policy.dart';
import 'trip_reminder_scheduler.dart';

class DeviceNotificationsState extends Equatable {
  const DeviceNotificationsState({
    this.remindersSupported = false,
    this.pushAvailable = false,
    this.permission = NotificationPermission.unsupported,
    this.remindersEnabled = true,
    this.tokenRegistered = false,
    this.deniedSerial = 0,
  });

  /// Local trip reminders work on this platform (Android / iOS).
  final bool remindersSupported;

  /// Firebase Cloud Messaging initialised (configured platform).
  final bool pushAvailable;
  final NotificationPermission permission;

  /// The user's local preference for trip reminders on this device.
  final bool remindersEnabled;

  /// This device's FCM token is registered for the signed-in user.
  final bool tokenRegistered;

  /// Bumped when a permission request is refused, for a one-off message.
  final int deniedSerial;

  DeviceNotificationsState copyWith({
    bool? remindersSupported,
    bool? pushAvailable,
    NotificationPermission? permission,
    bool? remindersEnabled,
    bool? tokenRegistered,
    int? deniedSerial,
  }) =>
      DeviceNotificationsState(
        remindersSupported: remindersSupported ?? this.remindersSupported,
        pushAvailable: pushAvailable ?? this.pushAvailable,
        permission: permission ?? this.permission,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        tokenRegistered: tokenRegistered ?? this.tokenRegistered,
        deniedSerial: deniedSerial ?? this.deniedSerial,
      );

  @override
  List<Object?> get props =>
      [remindersSupported, pushAvailable, permission, remindersEnabled, tokenRegistered, deniedSerial];
}

/// Device-side notifications, kept separate from the server's `notifications`
/// table (NotificationsCubit):
///
/// * **Local trip reminders** — scheduled on this device from confirmed
///   bookings ([TripReminderScheduler]).
/// * **FCM** — this device's token registered in `device_tokens` for the
///   signed-in user ([PushTokenSync]); incoming pushes only trigger a refresh
///   of the server notifications or open a booking.
///
/// Follows the session: on sign-in it re-syncs reminders from the user's
/// bookings and registers the token; before sign-out it unregisters the
/// token; on sign-out it removes every reminder. Nothing here can block the
/// app: when notifications are unavailable it simply does nothing.
class DeviceNotificationsCubit extends Cubit<DeviceNotificationsState> {
  DeviceNotificationsCubit({
    required LocalReminderNotifier notifier,
    required PushMessaging push,
    required PushTokenSync tokenSync,
    required TripReminderScheduler reminders,
    required BookingRepository bookings,
    required SessionCubit session,
    required AppPreferences preferences,
    Locale Function()? locale,
  })  : _notifier = notifier,
        _locale = locale ?? (() => const Locale('en')),
        _push = push,
        _tokenSync = tokenSync,
        _reminders = reminders,
        _bookings = bookings,
        _session = session,
        _prefs = preferences,
        super(DeviceNotificationsState(remindersEnabled: preferences.tripRemindersEnabled));

  final LocalReminderNotifier _notifier;
  final PushMessaging _push;
  final PushTokenSync _tokenSync;
  final TripReminderScheduler _reminders;
  final BookingRepository _bookings;
  final SessionCubit _session;
  final AppPreferences _prefs;
  final Locale Function() _locale;

  final _openBooking = StreamController<String>.broadcast();
  final _foregroundPush = StreamController<PushMessage>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _userId;
  bool _started = false;

  /// Booking ids to open because the user tapped a reminder or push.
  Stream<String> get openBookingRequests => _openBooking.stream;

  /// A push arrived while the app is open. The OS shows no banner for it then,
  /// so the app refreshes its server notifications and shows one in-app
  /// message — never a second (local) notification.
  Stream<PushMessage> get foregroundPushes => _foregroundPush.stream;

  /// Subscribes to taps, pushes and the session. Call once, after listening
  /// to [openBookingRequests]. Safe if notifications are unavailable.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final remindersOk = await _notifier.initialize();
    final pushOk = await _push.initialize();
    if (isClosed) return;
    emit(state.copyWith(
      remindersSupported: remindersOk,
      pushAvailable: pushOk,
      permission: await _readPermission(),
    ));

    await _ensureBookingUpdatesChannel();
    _session.addBeforeSignOutHook(_beforeSignOut);
    _tokenSync.start();
    _subscriptions
      ..add(_notifier.taps.listen((payload) => _open(TripReminderPayload.decode(payload)?.bookingId)))
      ..add(_push.openedMessages.listen((m) => _open(m.bookingId)))
      ..add(_push.foregroundMessages.listen(_foregroundPush.add))
      ..add(_session.stream.listen(_onSession));

    _open(TripReminderPayload.decode(await _notifier.launchPayload())?.bookingId);
    _open((await _push.initialMessage())?.bookingId);
    await _onSession(_session.state);
  }

  Future<void> _onSession(SessionState session) async {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _tokenSync.forget();
      if (!isClosed) emit(state.copyWith(tokenRegistered: false));
      await _reminders.clear();
      return;
    }
    await _reminders.activate(userId);
    await _resyncReminders(userId);
    await _registerToken(userId);
  }

  /// One network read per session start: the user's bookings, which the
  /// reminder-syncing repository reconciles reminders against.
  Future<void> _resyncReminders(String userId) async {
    if (!state.remindersSupported || !state.remindersEnabled) return;
    try {
      await _bookings.fetchMyBookings();
    } catch (error) {
      AppLogger.error('Trip reminders: startup resync failed', error: error);
    }
  }

  Future<void> _registerToken(String userId) async {
    if (!state.pushAvailable || state.permission != NotificationPermission.granted) return;
    final ok = await _tokenSync.attach(userId);
    if (!isClosed && _userId == userId) emit(state.copyWith(tokenRegistered: ok));
  }

  Future<void> _beforeSignOut() async {
    await _tokenSync.detach();
    if (!isClosed) emit(state.copyWith(tokenRegistered: false));
  }

  void _open(String? bookingId) {
    // Only real booking ids; the details screen re-reads it from Supabase
    // (and shows "not found" if it no longer exists or isn't the user's).
    if (bookingId != null && isUuid(bookingId)) _openBooking.add(bookingId);
  }

  Future<NotificationPermission> _readPermission() async {
    if (!_notifier.isSupported) return NotificationPermission.unsupported;
    final permission = await _notifier.permission();
    if (permission == NotificationPermission.denied && !_prefs.notificationPermissionRequested) {
      return NotificationPermission.notDetermined;
    }
    return permission;
  }

  /// Shows the OS prompt (where the OS still allows one).
  Future<void> requestPermission() async {
    if (!state.remindersSupported) return;
    final result = await _notifier.requestPermission();
    await _prefs.setNotificationPermissionRequested();
    if (isClosed) return;
    emit(state.copyWith(
      permission: result,
      deniedSerial: result == NotificationPermission.denied ? state.deniedSerial + 1 : null,
    ));
    final userId = _userId;
    if (result == NotificationPermission.granted && userId != null) await _registerToken(userId);
  }

  /// After the first successful booking: ask once, in context. Never again
  /// unprompted.
  Future<void> requestPermissionAfterBooking() async {
    if (state.permission == NotificationPermission.notDetermined && state.remindersEnabled) {
      await requestPermission();
    }
  }

  /// Re-reads the OS permission (e.g. when the app returns to the
  /// foreground after the user changed it in system settings).
  Future<void> refreshPermission() async {
    if (!state.remindersSupported) return;
    final permission = await _readPermission();
    if (isClosed) return;
    if (permission != state.permission) emit(state.copyWith(permission: permission));
    final userId = _userId;
    // Also retries a registration that failed earlier (e.g. offline).
    if (permission == NotificationPermission.granted && userId != null && !state.tokenRegistered) {
      await _registerToken(userId);
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    if (!state.remindersSupported) return;
    await _prefs.setTripRemindersEnabled(enabled);
    if (isClosed) return;
    emit(state.copyWith(remindersEnabled: enabled));
    final userId = _userId;
    if (enabled && userId != null) {
      await _resyncReminders(userId);
      if (state.permission == NotificationPermission.notDetermined) await requestPermission();
    } else {
      await _reminders.resync(); // removes them
    }
  }

  Future<bool> openSystemSettings() => _notifier.openSystemSettings();

  /// The app language changed: rebuild reminder texts and the channel name
  /// (no network call).
  Future<void> languageChanged() async {
    await _ensureBookingUpdatesChannel();
    await _reminders.resync();
  }

  /// The Android channel for remote pushes, named in the app language.
  Future<void> _ensureBookingUpdatesChannel() async {
    if (!state.remindersSupported) return;
    final l10n = lookupAppLocalizations(Locale(_locale().languageCode));
    await _notifier.ensureBookingUpdatesChannel(
      name: l10n.bookingUpdatesChannelName,
      description: l10n.bookingUpdatesChannelDescription,
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _tokenSync.dispose();
    await _openBooking.close();
    await _foregroundPush.close();
    return super.close();
  }
}
