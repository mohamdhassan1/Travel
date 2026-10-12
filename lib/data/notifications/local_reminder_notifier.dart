import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/app_logger.dart';

/// OS notification permission as far as the app can tell.
enum NotificationPermission {
  granted,
  denied,

  /// Never requested on this device (the coordinator decides this from its
  /// own record; platforms report "not determined" as "not granted").
  notDetermined,

  /// This platform has no local / push notification support in this app
  /// (e.g. the web build).
  unsupported,
}

/// A local notification the OS still has scheduled.
class ScheduledReminder {
  const ScheduledReminder(this.id, this.payload);
  final int id;
  final String? payload;
}

/// Device-local scheduled notifications (trip reminders). The only place the
/// app talks to `flutter_local_notifications`; everything above it depends on
/// this interface so it can be faked in tests.
abstract interface class LocalReminderNotifier {
  bool get isSupported;

  /// Sets up the plugin. Returns `false` (never throws) if unavailable.
  Future<bool> initialize();

  /// [NotificationPermission.granted], [NotificationPermission.denied] or
  /// [NotificationPermission.unsupported].
  Future<NotificationPermission> permission();

  /// Shows the system prompt where the OS still allows it.
  Future<NotificationPermission> requestPermission();

  /// Opens this app's notification settings. `false` if not possible.
  Future<bool> openSystemSettings();

  /// Creates (or renames, on a language change) the Android channel that
  /// remote booking pushes use. No-op elsewhere.
  Future<void> ensureBookingUpdatesChannel({required String name, required String description});

  /// Schedules (or replaces, for the same [id]) a reminder at [at], an
  /// absolute moment.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String channelName,
    required String channelDescription,
  });

  Future<void> cancel(int id);

  Future<List<ScheduledReminder>> pending();

  /// Payloads of notifications the user tapped while the app was running.
  Stream<String?> get taps;

  /// Payload of the notification that launched the app from terminated.
  Future<String?> launchPayload();
}

/// `flutter_local_notifications` on Android and iOS. Unsupported elsewhere
/// (including web, where scheduled notifications aren't available).
class FlutterLocalReminderNotifier implements LocalReminderNotifier {
  FlutterLocalReminderNotifier({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String?>.broadcast();
  bool _ready = false;

  /// Channel for scheduled trip reminders.
  static const channelId = 'trip_reminders';

  /// Channel for remote booking pushes (must match the Edge Function and the
  /// `default_notification_channel_id` in AndroidManifest.xml).
  static const bookingUpdatesChannelId = 'booking_updates';

  @override
  bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> initialize() async {
    if (!isSupported) return false;
    if (_ready) return true;
    try {
      _ready = await _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@drawable/ic_stat_rahala'),
              // Permission is requested later, in context — not at launch.
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
            onDidReceiveNotificationResponse: (response) => _taps.add(response.payload),
          ) ??
          false;
    } catch (error, stack) {
      AppLogger.error('Local notifications unavailable', error: error, stackTrace: stack);
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<NotificationPermission> permission() async {
    if (!_ready) return NotificationPermission.unsupported;
    try {
      final enabled = defaultTargetPlatform == TargetPlatform.android
          ? await _android?.areNotificationsEnabled()
          : (await _ios?.checkPermissions())?.isEnabled;
      return enabled == true ? NotificationPermission.granted : NotificationPermission.denied;
    } catch (error) {
      AppLogger.error('Could not read notification permission', error: error);
      return NotificationPermission.denied;
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!_ready) return NotificationPermission.unsupported;
    try {
      final granted = defaultTargetPlatform == TargetPlatform.android
          ? await _android?.requestNotificationsPermission()
          : await _ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted == true ? NotificationPermission.granted : NotificationPermission.denied;
    } catch (error) {
      AppLogger.error('Notification permission request failed', error: error);
      return NotificationPermission.denied;
    }
  }

  @override
  Future<bool> openSystemSettings() async {
    if (!_ready) return false;
    try {
      final opened = defaultTargetPlatform == TargetPlatform.android
          ? await _android?.openAppNotificationSettings()
          : await _ios?.openAppNotificationSettings();
      return opened ?? false;
    } catch (error) {
      AppLogger.error('Could not open notification settings', error: error);
      return false;
    }
  }

  @override
  Future<void> ensureBookingUpdatesChannel({required String name, required String description}) async {
    if (!_ready || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _android?.createNotificationChannel(AndroidNotificationChannel(
        bookingUpdatesChannelId,
        name,
        description: description,
        importance: Importance.high,
      ));
    } catch (error) {
      AppLogger.error('Could not create the booking updates channel', error: error);
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: id,
      // An absolute instant: correct whatever the device's time zone is, and
      // needs no time-zone database.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          icon: 'ic_stat_rahala',
          color: const Color(0xFF0F766E),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // A reminder a day ahead doesn't need to the minute: inexact alarms
      // avoid the special exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (_ready) await _plugin.cancel(id: id);
  }

  @override
  Future<List<ScheduledReminder>> pending() async {
    if (!_ready) return const [];
    final requests = await _plugin.pendingNotificationRequests();
    return [for (final r in requests) ScheduledReminder(r.id, r.payload)];
  }

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    if (!_ready) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return details?.didNotificationLaunchApp == true ? details?.notificationResponse?.payload : null;
    } catch (error) {
      AppLogger.error('Could not read notification launch details', error: error);
      return null;
    }
  }
}
