import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notifications_repository.dart';
import '../auth/session_cubit.dart';

enum NotificationsStatus {
  /// No signed-in user: nothing loaded, nothing shown.
  signedOut,
  loading,
  ready,
  failure,
}

/// A failed refresh / mark-read, for a snack bar. [serial] makes repeated
/// identical failures distinct.
class NotificationsActionFailure extends Equatable {
  const NotificationsActionFailure(this.failure, this.serial);

  final AppFailure failure;
  final int serial;

  @override
  List<Object?> get props => [failure, serial];
}

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.signedOut,
    this.items = const [],
    this.failure,
    this.refreshing = false,
    this.markingAll = false,
    this.lastActionFailure,
  });

  final NotificationsStatus status;

  /// Newest first, exactly as the server returned them.
  final List<AppNotification> items;

  /// Why the initial load failed (status [NotificationsStatus.failure]).
  final AppFailure? failure;

  /// A background reload while [items] stay on screen.
  final bool refreshing;
  final bool markingAll;
  final NotificationsActionFailure? lastActionFailure;

  int get unreadCount => items.where((n) => !n.isRead).length;
  bool get isEmpty => status == NotificationsStatus.ready && items.isEmpty;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    bool? refreshing,
    bool? markingAll,
    NotificationsActionFailure? lastActionFailure,
  }) =>
      NotificationsState(
        status: status ?? this.status,
        items: items ?? this.items,
        failure: failure,
        refreshing: refreshing ?? this.refreshing,
        markingAll: markingAll ?? this.markingAll,
        lastActionFailure: lastActionFailure ?? this.lastActionFailure,
      );

  @override
  List<Object?> get props => [status, items, failure, refreshing, markingAll, lastActionFailure];
}

/// The signed-in user's notifications, shared by the Account badge and the
/// Notifications screen.
///
/// * Follows the session: loads on sign-in, clears on sign-out and when a
///   different user signs in — nothing leaks between accounts.
/// * Read state only changes when the server confirms it: the rows returned
///   by `mark_notifications_read` replace the local ones.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, SessionCubit session) : super(const NotificationsState()) {
    _sessionSubscription = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final NotificationsRepository _repository;
  late final StreamSubscription<SessionState> _sessionSubscription;
  String? _userId;
  int _serial = 0;

  void _onSession(SessionState session) {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    // Drop everything from the previous account before anything else.
    emit(const NotificationsState());
    if (userId != null) load();
  }

  /// Full load with a loading state (first load, or retry after a failure).
  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    emit(const NotificationsState(status: NotificationsStatus.loading));
    try {
      final items = await _repository.fetchMine();
      if (isClosed || _userId != userId) return;
      emit(NotificationsState(status: NotificationsStatus.ready, items: items));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      emit(NotificationsState(status: NotificationsStatus.failure, failure: failure));
    }
  }

  /// Reloads while keeping the current list visible (pull-to-refresh, opening
  /// Account). Falls back to [load] if nothing has loaded yet.
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null || state.refreshing || state.status == NotificationsStatus.loading) return;
    if (state.status != NotificationsStatus.ready) return load();
    emit(state.copyWith(refreshing: true));
    try {
      final items = await _repository.fetchMine();
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(items: items, refreshing: false));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(refreshing: false, lastActionFailure: NotificationsActionFailure(failure, ++_serial)));
    }
  }

  /// Marks one notification read on the server (no-op if it already is).
  Future<void> markRead(String id) async {
    final userId = _userId;
    final item = state.items.where((n) => n.id == id).firstOrNull;
    if (userId == null || item == null || item.isRead) return;
    try {
      final updated = await _repository.markRead([id]);
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(items: _merge(state.items, updated)));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(lastActionFailure: NotificationsActionFailure(failure, ++_serial)));
    }
  }

  Future<void> markAllRead() async {
    final userId = _userId;
    if (userId == null || state.markingAll || state.unreadCount == 0) return;
    emit(state.copyWith(markingAll: true));
    try {
      final updated = await _repository.markAllRead();
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(items: _merge(state.items, updated), markingAll: false));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(markingAll: false, lastActionFailure: NotificationsActionFailure(failure, ++_serial)));
    }
  }

  /// Applies the server's read state for the rows it returned.
  static List<AppNotification> _merge(List<AppNotification> items, List<AppNotification> updated) {
    final readAt = {for (final n in updated) n.id: n.readAt};
    return [for (final n in items) readAt.containsKey(n.id) ? n.withReadAt(readAt[n.id]) : n];
  }

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    return super.close();
  }
}
