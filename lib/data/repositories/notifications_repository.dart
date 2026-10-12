import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/app_notification.dart';
import 'catalog_repository.dart' show isUuid;
import 'supabase_error_mapper.dart';

/// The signed-in user's notifications (`public.notifications`). Throws
/// `AppFailure`.
///
/// Rows are created only by the database (booking triggers); RLS exposes
/// just the caller's own rows, and read state changes go through the
/// `mark_notifications_read` function, which stamps `read_at` with the
/// server's clock.
abstract interface class NotificationsRepository {
  /// Newest first, at most [limit].
  Future<List<AppNotification>> fetchMine({int limit = 100});

  /// Marks [ids] read. Returns the rows the server actually changed (already
  /// read or unknown ids are simply absent).
  Future<List<AppNotification>> markRead(List<String> ids);

  /// Marks every unread notification of the user read; returns those rows.
  Future<List<AppNotification>> markAllRead();
}

class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository(
    this._client, {
    required String? Function() currentUserId,
    this.timeout = const Duration(seconds: 15),
  }) : _currentUserId = currentUserId;

  final SupabaseClient _client;
  final String? Function() _currentUserId;
  final Duration timeout;

  static const _table = 'notifications';
  static const _markReadFunction = 'mark_notifications_read';

  @override
  Future<List<AppNotification>> fetchMine({int limit = 100}) => _run('load', () async {
        _requireUser();
        // postgrest-dart's `.order()` defaults to DESCENDING; be explicit.
        final rows = await _client
            .from(_table)
            .select('id, type, booking_id, data, read_at, created_at')
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(limit)
            .timeout(timeout);
        return parseNotificationRows(rows);
      });

  @override
  Future<List<AppNotification>> markRead(List<String> ids) => _run('mark read', () async {
        _requireUser();
        final valid = ids.where(isUuid).toSet().toList();
        if (valid.isEmpty) return const <AppNotification>[];
        return _markRead(valid);
      });

  @override
  Future<List<AppNotification>> markAllRead() => _run('mark all read', () async {
        _requireUser();
        return _markRead(null);
      });

  Future<List<AppNotification>> _markRead(List<String>? ids) async {
    final result = await _client.rpc<dynamic>(_markReadFunction, params: {'p_ids': ids}).timeout(timeout);
    if (result is! List) throw FormatException('Unexpected $_markReadFunction result', result);
    return parseNotificationRows(result);
  }

  void _requireUser() {
    if (_currentUserId() == null) {
      throw const AppFailure(FailureType.sessionExpired, debugMessage: 'No signed-in user');
    }
  }

  Future<T> _run<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stack) {
      final failure = mapSupabaseError(error);
      AppLogger.error('Notifications: $action failed (${failure.type.name})',
          error: failure.debugMessage, stackTrace: stack);
      throw failure;
    }
  }
}

/// Parses rows, skipping (and logging) any the app can't display — e.g. a
/// notification type added to the database after this app version — rather
/// than failing the whole list.
List<AppNotification> parseNotificationRows(List<dynamic> rows) {
  final parsed = <AppNotification>[];
  for (final row in rows) {
    try {
      if (row is! Map<String, dynamic>) throw FormatException('Expected object', row);
      parsed.add(AppNotification.fromJson(row));
    } on FormatException catch (error) {
      AppLogger.error('Skipping unreadable notification', error: error);
    }
  }
  return parsed;
}
