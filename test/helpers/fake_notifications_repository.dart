import 'dart:async';

import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/app_notification.dart';
import 'package:rahala/data/repositories/notifications_repository.dart';

/// Behaves like `public.notifications` under RLS plus
/// `mark_notifications_read`: rows are per user and read state is set by the
/// "server" (this fake), never by the caller.
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({String? Function()? currentUserId, DateTime Function()? now})
      : _currentUserId = currentUserId ?? (() => 'user-1'),
        _now = now ?? (() => DateTime.utc(2026, 10, 2, 12));

  final String? Function() _currentUserId;
  final DateTime Function() _now;
  final _rows = <({String userId, AppNotification notification})>[];
  int _sequence = 0;

  AppFailure? nextLoadFailure;
  AppFailure? nextMarkFailure;
  Completer<void>? loadGate;
  final calls = <String>[];

  String _user() => _currentUserId() ?? (throw const AppFailure(FailureType.sessionExpired));

  AppNotification add({
    required String userId,
    NotificationType type = NotificationType.bookingConfirmed,
    String? bookingId = 'bk-1',
    String? reference = 'RH-1A2B3C4D',
    DateTime? travelDate,
    String? destinationNameEn = 'Cairo',
    String? destinationNameAr = 'القاهرة',
    bool read = false,
  }) {
    final n = AppNotification(
      id: 'nt-${++_sequence}',
      type: type,
      bookingId: bookingId,
      reference: reference,
      travelDate: travelDate ?? DateTime(2026, 11, 20),
      destinationNameEn: destinationNameEn,
      destinationNameAr: destinationNameAr,
      readAt: read ? _now() : null,
      createdAt: DateTime.utc(2026, 10, 1, 9).add(Duration(minutes: _sequence)),
    );
    _rows.add((userId: userId, notification: n));
    return n;
  }

  AppNotification stored(String id) => _rows.firstWhere((r) => r.notification.id == id).notification;

  @override
  Future<List<AppNotification>> fetchMine({int limit = 100}) async {
    final user = _user();
    calls.add('list:$user');
    await loadGate?.future;
    final failure = nextLoadFailure;
    if (failure != null) {
      nextLoadFailure = null;
      throw failure;
    }
    final mine = [
      for (final r in _rows)
        if (r.userId == user) r.notification
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine.take(limit).toList();
  }

  @override
  Future<List<AppNotification>> markRead(List<String> ids) => _mark(ids);

  @override
  Future<List<AppNotification>> markAllRead() => _mark(null);

  Future<List<AppNotification>> _mark(List<String>? ids) async {
    final user = _user();
    calls.add(ids == null ? 'markAll' : 'mark:${ids.join(',')}');
    final failure = nextMarkFailure;
    if (failure != null) {
      nextMarkFailure = null;
      throw failure;
    }
    final changed = <AppNotification>[];
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (r.userId != user || r.notification.isRead) continue;
      if (ids != null && !ids.contains(r.notification.id)) continue;
      final updated = r.notification.withReadAt(_now());
      _rows[i] = (userId: r.userId, notification: updated);
      changed.add(updated);
    }
    return changed;
  }
}
