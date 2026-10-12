import 'dart:async';

import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/notifications/local_reminder_notifier.dart';
import 'package:rahala/data/notifications/push_messaging.dart';
import 'package:rahala/data/repositories/device_token_repository.dart';

/// Behaves like the OS scheduler: one pending notification per id (the same
/// id replaces), tapped payloads arrive on [taps].
class FakeLocalReminderNotifier implements LocalReminderNotifier {
  FakeLocalReminderNotifier({
    this.supported = true,
    this.osPermission = NotificationPermission.denied,
    this.grantOnRequest = true,
    this.launch,
  });

  final bool supported;

  /// What the OS reports before/after a request.
  NotificationPermission osPermission;
  bool grantOnRequest;
  String? launch;
  bool failSchedule = false;

  bool initialized = false;
  int permissionRequests = 0;
  int settingsOpened = 0;
  int scheduleCalls = 0;
  final scheduled = <int, ({DateTime at, String title, String body, String payload})>{};
  final _taps = StreamController<String?>.broadcast();

  void tap(String? payload) => _taps.add(payload);

  @override
  bool get isSupported => supported;

  @override
  Future<bool> initialize() async => initialized = supported;

  @override
  Future<NotificationPermission> permission() async => initialized ? osPermission : NotificationPermission.unsupported;

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!initialized) return NotificationPermission.unsupported;
    permissionRequests++;
    if (grantOnRequest) osPermission = NotificationPermission.granted;
    return osPermission;
  }

  ({String name, String description})? bookingUpdatesChannel;

  @override
  Future<void> ensureBookingUpdatesChannel({required String name, required String description}) async {
    if (initialized) bookingUpdatesChannel = (name: name, description: description);
  }

  @override
  Future<bool> openSystemSettings() async {
    settingsOpened++;
    return initialized;
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
    if (!initialized) return;
    if (failSchedule) throw StateError('scheduling failed');
    scheduleCalls++;
    scheduled[id] = (at: at, title: title, body: body, payload: payload);
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<List<ScheduledReminder>> pending() async => [
        for (final e in scheduled.entries) ScheduledReminder(e.key, e.value.payload),
      ];

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async => launch;
}

/// FCM stand-in: a controllable token, refresh stream and messages.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging(
      {this.available = true, this.currentToken = defaultToken, this.devicePlatform = DevicePlatform.android});

  static const defaultToken = 'fcm-token-AAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  bool available;
  String? currentToken;
  DevicePlatform? devicePlatform;
  PushMessage? initial;
  bool initialized = false;
  final _refresh = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  void refreshToken(String token) {
    currentToken = token;
    _refresh.add(token);
  }

  void receiveForeground(PushMessage m) => _foreground.add(m);
  void open(PushMessage m) => _opened.add(m);

  @override
  bool get isAvailable => initialized && available;

  @override
  DevicePlatform? get platform => devicePlatform;

  @override
  Future<bool> initialize() async {
    initialized = true;
    return available;
  }

  @override
  Future<String?> token() async => isAvailable ? currentToken : null;

  @override
  Stream<String> get tokenRefresh => _refresh.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => initial;
}

/// Mirrors `register_device_token` / `unregister_device_token` under RLS:
/// one row per token, owned by whoever registered it last; only the owner
/// can delete it; no session → rejected.
class FakeDeviceTokenRepository implements DeviceTokenRepository {
  FakeDeviceTokenRepository({required String? Function() currentUserId}) : _currentUserId = currentUserId;

  final String? Function() _currentUserId;
  final rows = <String, ({String userId, DevicePlatform platform})>{};
  final calls = <String>[];
  AppFailure? nextFailure;

  String _user() => _currentUserId() ?? (throw const AppFailure(FailureType.sessionExpired));

  void _maybeFail() {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
  }

  @override
  Future<void> register(String token, DevicePlatform platform) async {
    final user = _user();
    calls.add('register:$user');
    _maybeFail();
    rows[token] = (userId: user, platform: platform);
  }

  @override
  Future<void> unregister(String token) async {
    final user = _user();
    calls.add('unregister:$user');
    _maybeFail();
    if (rows[token]?.userId == user) rows.remove(token);
  }

  List<String> tokensOf(String userId) => [
        for (final e in rows.entries)
          if (e.value.userId == userId) e.key
      ];
}
