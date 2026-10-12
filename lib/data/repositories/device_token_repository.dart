import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../notifications/push_messaging.dart' show DevicePlatform;
import 'supabase_error_mapper.dart';

/// Registers this device's FCM token for the signed-in user
/// (`public.device_tokens`). Throws `AppFailure`.
///
/// Only the database functions are used: `register_device_token` takes the
/// owner from `auth.uid()` (a token moves to whoever signs in on the device;
/// there's one row per token) and `unregister_device_token` deletes only the
/// caller's own row. The table itself is read-only for clients.
abstract interface class DeviceTokenRepository {
  Future<void> register(String token, DevicePlatform platform);
  Future<void> unregister(String token);
}

class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  SupabaseDeviceTokenRepository(
    this._client, {
    required String? Function() currentUserId,
    this.timeout = const Duration(seconds: 15),
  }) : _currentUserId = currentUserId;

  final SupabaseClient _client;
  final String? Function() _currentUserId;
  final Duration timeout;

  @override
  Future<void> register(String token, DevicePlatform platform) => _run('register', () async {
        _requireUser();
        _validate(token);
        await _client.rpc<dynamic>('register_device_token', params: {
          'p_token': token,
          'p_platform': platform.name,
        }).timeout(timeout);
      });

  @override
  Future<void> unregister(String token) => _run('unregister', () async {
        _requireUser();
        _validate(token);
        await _client.rpc<dynamic>('unregister_device_token', params: {'p_token': token}).timeout(timeout);
      });

  /// Mirrors the `device_tokens_token_check` constraint.
  void _validate(String token) {
    if (token.length < 20 || token.length > 4096) {
      throw const AppFailure(FailureType.invalidInput, debugMessage: 'Device token length out of range');
    }
  }

  void _requireUser() {
    if (_currentUserId() == null) {
      throw const AppFailure(FailureType.sessionExpired, debugMessage: 'No signed-in user');
    }
  }

  Future<void> _run(String action, Future<void> Function() body) async {
    try {
      await body();
    } catch (error, stack) {
      final failure = mapSupabaseError(error);
      // Never log the token itself.
      AppLogger.error('Device token: $action failed (${failure.type.name})',
          error: failure.debugMessage, stackTrace: stack);
      throw failure;
    }
  }
}
