import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import 'supabase_error_mapper.dart';

/// The signed-in user's own profile and photo. Throws `AppFailure`.
///
/// Everything is scoped by the server: RLS lets a user read/update only their
/// own `profiles` row (only `full_name`, `phone`, `avatar_path`,
/// `preferred_locale` are client-updatable), and the private `avatars` bucket
/// only accepts objects under `<user id>/`. A CHECK constraint ties
/// `avatar_path` to that folder.
abstract interface class ProfileRepository {
  Future<UserProfile> fetchMyProfile();

  /// Updates the editable fields. A `null`/blank [phone] clears it. Returns
  /// the row as stored. Never touches email, password, avatar or locale.
  Future<UserProfile> updateProfile({required String fullName, String? phone});

  /// Uploads a new photo, points the profile at it, then deletes the old
  /// one. [contentType] must be image/jpeg, image/png or image/webp.
  Future<UserProfile> uploadAvatar(Uint8List bytes, String contentType);

  /// Clears the profile photo and deletes the stored file.
  Future<UserProfile> removeAvatar();

  /// A short-lived URL for a private avatar object.
  Future<String> avatarUrl(String path);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(
    this._client, {
    this.timeout = const Duration(seconds: 15),
    this.uploadTimeout = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final Duration timeout;
  final Duration uploadTimeout;
  final DateTime Function() _now;

  static const bucket = 'avatars';

  /// Mirrors the bucket's limit (2 MB) so oversized photos fail fast.
  static const maxAvatarBytes = 2 * 1024 * 1024;
  static const _extensions = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp'};

  static const _columns = 'id, full_name, phone, avatar_path, preferred_locale, created_at, updated_at';

  String _requireUser() =>
      _client.auth.currentUser?.id ??
      (throw const AppFailure(FailureType.sessionExpired, debugMessage: 'No signed-in user'));

  @override
  Future<UserProfile> fetchMyProfile() => _run('load', () async {
        final userId = _requireUser();
        // RLS only ever returns the caller's own row; the filter just makes the
        // intent explicit and lets PostgREST use the primary key.
        final row = await _client.from('profiles').select(_columns).eq('id', userId).maybeSingle().timeout(timeout);
        // The sign-up trigger should always create it; surface it if not.
        if (row == null) throw AppFailure(FailureType.notFound, debugMessage: 'No profile row for $userId');
        return UserProfile.fromJson(row);
      });

  @override
  Future<UserProfile> updateProfile({required String fullName, String? phone}) => _run('update', () async {
        final userId = _requireUser();
        final trimmedPhone = phone?.trim();
        return _update(userId, {
          'full_name': fullName.trim(),
          'phone': (trimmedPhone == null || trimmedPhone.isEmpty) ? null : trimmedPhone,
        });
      });

  @override
  Future<UserProfile> uploadAvatar(Uint8List bytes, String contentType) => _run('upload avatar', () async {
        final userId = _requireUser();
        final ext = _extensions[contentType];
        if (ext == null) throw AppFailure(FailureType.invalidInput, debugMessage: 'Unsupported type $contentType');
        if (bytes.isEmpty || bytes.length > maxAvatarBytes) {
          throw AppFailure(FailureType.invalidInput, debugMessage: 'Avatar size ${bytes.length} out of range');
        }
        final previous = (await fetchMyProfile()).avatarPath;
        // A new name per upload: no stale CDN/browser cache, and the old file
        // stays valid until the profile points at the new one.
        final path = '$userId/avatar-${_now().millisecondsSinceEpoch}.$ext';
        await _client.storage
            .from(bucket)
            .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType))
            .timeout(uploadTimeout);
        final UserProfile updated;
        try {
          updated = await _update(userId, {'avatar_path': path});
        } catch (_) {
          await _deleteQuietly(path); // don't leave an orphan behind
          rethrow;
        }
        if (previous != null && previous != path) await _deleteQuietly(previous);
        return updated;
      });

  @override
  Future<UserProfile> removeAvatar() => _run('remove avatar', () async {
        final userId = _requireUser();
        final previous = (await fetchMyProfile()).avatarPath;
        final updated = await _update(userId, {'avatar_path': null});
        if (previous != null) await _deleteQuietly(previous);
        return updated;
      });

  @override
  Future<String> avatarUrl(String path) => _run('avatar url', () async {
        final userId = _requireUser();
        // Never ask for another user's object (the bucket would refuse anyway).
        if (!path.startsWith('$userId/')) throw const AppFailure(FailureType.permissionDenied);
        return _client.storage.from(bucket).createSignedUrl(path, 60 * 60).timeout(timeout);
      });

  /// PATCH that returns the stored row (`.select().single()` → one object).
  Future<UserProfile> _update(String userId, Map<String, dynamic> values) async {
    final row =
        await _client.from('profiles').update(values).eq('id', userId).select(_columns).single().timeout(timeout);
    return UserProfile.fromJson(row);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await _client.storage.from(bucket).remove([path]).timeout(timeout);
    } catch (error) {
      AppLogger.error('Profile: could not delete old avatar object', error: error);
    }
  }

  Future<T> _run<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stack) {
      final failure = mapSupabaseError(error);
      AppLogger.error('Profile: $action failed (${failure.type.name})', error: failure.debugMessage, stackTrace: stack);
      throw failure;
    }
  }
}
