import 'dart:async';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../../data/notifications/push_messaging.dart';
import '../../data/repositories/device_token_repository.dart';

/// Keeps this device's FCM token registered for exactly the signed-in user.
///
/// * [attach] registers the current token for a user (skipped if that exact
///   token is already registered for them — no duplicate calls).
/// * Token refresh re-registers for the attached user and drops the old one.
/// * [detach] unregisters while the session is still valid (before sign-out);
///   [forget] only clears local state (the session already ended — the next
///   sign-in on this device re-assigns the token server-side).
class PushTokenSync {
  PushTokenSync(this._push, this._tokens);

  final PushMessaging _push;
  final DeviceTokenRepository _tokens;

  String? _userId;
  ({String token, String userId})? _registered;
  StreamSubscription<String>? _refreshSubscription;
  Future<void> _queue = Future.value();

  /// The token currently registered server-side for the attached user.
  String? get registeredToken => _registered?.token;
  String? get attachedUserId => _userId;

  /// Starts listening for token refreshes (once).
  void start() {
    _refreshSubscription ??= _push.tokenRefresh.listen((token) => _enqueue(() => _onRefresh(token)));
  }

  /// Registers this device for [userId]. Returns `false` if push is
  /// unavailable or registration failed.
  Future<bool> attach(String userId) async {
    var ok = false;
    await _enqueue(() async {
      _userId = userId;
      if (!_push.isAvailable || _push.platform == null) return;
      final token = await _push.token();
      if (token == null || _userId != userId) return;
      ok = await _register(token, userId);
    });
    return ok;
  }

  Future<void> detach() => _enqueue(() async {
        final registered = _registered;
        _userId = null;
        _registered = null;
        if (registered == null) return;
        try {
          await _tokens.unregister(registered.token);
        } on AppFailure catch (failure) {
          AppLogger.error('Could not unregister the device token (${failure.type.name})');
        }
      });

  void forget() {
    _userId = null;
    _registered = null;
  }

  Future<void> _onRefresh(String token) async {
    final userId = _userId;
    if (userId == null) return; // not signed in: registered on next sign-in
    final previous = _registered;
    if (await _register(token, userId) && previous != null && previous.token != token) {
      try {
        await _tokens.unregister(previous.token);
      } on AppFailure catch (failure) {
        AppLogger.error('Could not remove the replaced device token (${failure.type.name})');
      }
    }
  }

  Future<bool> _register(String token, String userId) async {
    if (_registered?.token == token && _registered?.userId == userId) return true;
    try {
      await _tokens.register(token, _push.platform!);
      _registered = (token: token, userId: userId);
      return true;
    } on AppFailure catch (failure) {
      AppLogger.error('Could not register the device token (${failure.type.name})');
      return false;
    }
  }

  Future<void> _enqueue(Future<void> Function() body) {
    final next = _queue.then((_) => body()).catchError((Object error, StackTrace stack) {
      AppLogger.error('Push token sync failed', error: error, stackTrace: stack);
    });
    _queue = next;
    return next;
  }

  Future<void> dispose() async => _refreshSubscription?.cancel();
}
