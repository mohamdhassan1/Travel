import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import 'catalog_repository.dart';
import 'supabase_error_mapper.dart';

/// The signed-in user's saved destinations (`public.favorites`).
///
/// Ownership is enforced by Row Level Security (`user_id = auth.uid()`); the
/// client never sends a user id — the column defaults to `auth.uid()`.
/// Throws `AppFailure`.
abstract interface class FavoritesRepository {
  /// Destination ids the current user has saved, newest first.
  Future<List<String>> fetchFavoriteIds();

  /// Idempotent: saving an already-saved destination succeeds.
  Future<void> addFavorite(String destinationId);

  /// Idempotent: removing a destination that isn't saved succeeds.
  Future<void> removeFavorite(String destinationId);
}

class SupabaseFavoritesRepository implements FavoritesRepository {
  SupabaseFavoritesRepository(
    this._client, {
    required String? Function() currentUserId,
    this.timeout = const Duration(seconds: 15),
  }) : _currentUserId = currentUserId;

  final SupabaseClient _client;
  final String? Function() _currentUserId;
  final Duration timeout;

  static const _table = 'favorites';

  @override
  Future<List<String>> fetchFavoriteIds() => _run('load', () async {
        _requireUser();
        final rows =
            await _client.from(_table).select('destination_id').order('created_at', ascending: false).timeout(timeout);
        return [
          for (final row in rows)
            if (row['destination_id'] case final String id) id,
        ];
      });

  @override
  Future<void> addFavorite(String destinationId) => _run('add', () async {
        _requireUser();
        if (!isUuid(destinationId)) throw const AppFailure(FailureType.notFound, debugMessage: 'Malformed id');
        try {
          await _client.from(_table).insert({'destination_id': destinationId}).timeout(timeout);
        } on PostgrestException catch (e) {
          // 23505: already saved (primary key user_id+destination_id) → fine.
          if (e.code == '23505') return;
          // 23503: the destination doesn't exist (foreign key).
          if (e.code == '23503') throw AppFailure(FailureType.notFound, debugMessage: e.message);
          rethrow;
        }
      });

  @override
  Future<void> removeFavorite(String destinationId) => _run('remove', () async {
        final userId = _requireUser();
        if (!isUuid(destinationId)) return;
        // RLS already restricts deletes to the caller's rows; filtering by
        // user_id as well documents intent and keeps the delete narrow.
        await _client.from(_table).delete().eq('user_id', userId).eq('destination_id', destinationId).timeout(timeout);
      });

  String _requireUser() {
    final id = _currentUserId();
    if (id == null) throw const AppFailure(FailureType.sessionExpired, debugMessage: 'No signed-in user');
    return id;
  }

  Future<T> _run<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stack) {
      final failure = mapSupabaseError(error);
      AppLogger.error('Favorites: $action failed (${failure.type.name})',
          error: failure.debugMessage, stackTrace: stack);
      throw failure;
    }
  }
}
