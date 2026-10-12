import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/repositories/favorites_repository.dart';
import '../auth/session_cubit.dart';

enum FavoritesStatus {
  /// No signed-in user: nothing loaded, nothing shown.
  signedOut,
  loading,
  ready,
  failure,
}

enum FavoriteChange { added, removed, addFailed, removeFailed }

/// One-shot result of a toggle, for snack bars. [serial] makes repeated
/// identical events distinct.
class FavoriteEvent extends Equatable {
  const FavoriteEvent(this.change, this.destinationId, this.serial, {this.failure});

  final FavoriteChange change;
  final String destinationId;
  final int serial;
  final AppFailure? failure;

  bool get failed => change == FavoriteChange.addFailed || change == FavoriteChange.removeFailed;

  @override
  List<Object?> get props => [change, destinationId, serial, failure];
}

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.signedOut,
    this.ids = const [],
    this.pending = const {},
    this.failure,
    this.lastEvent,
  });

  final FavoritesStatus status;

  /// Saved destination ids, newest first.
  final List<String> ids;

  /// Ids with a server request in flight (buttons are disabled meanwhile).
  final Set<String> pending;
  final AppFailure? failure;
  final FavoriteEvent? lastEvent;

  bool isFavorite(String destinationId) => ids.contains(destinationId);
  bool isPending(String destinationId) => pending.contains(destinationId);

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<String>? ids,
    Set<String>? pending,
    AppFailure? failure,
    FavoriteEvent? lastEvent,
  }) =>
      FavoritesState(
        status: status ?? this.status,
        ids: ids ?? this.ids,
        pending: pending ?? this.pending,
        failure: failure,
        lastEvent: lastEvent ?? this.lastEvent,
      );

  @override
  List<Object?> get props => [status, ids, pending, failure, lastEvent];
}

/// Single source of truth for the signed-in user's favourites, shared by the
/// list, details and favourites screens.
///
/// * Follows the session: loads on sign-in, clears on sign-out and when a
///   different user signs in — favourites never leak between accounts.
/// * Toggles are optimistic and rolled back if the server rejects them; the
///   UI is told via [FavoritesState.lastEvent] so it never claims a save that
///   didn't happen.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repository, SessionCubit session) : super(const FavoritesState()) {
    _sessionSubscription = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final FavoritesRepository _repository;
  late final StreamSubscription<SessionState> _sessionSubscription;
  String? _userId;
  int _serial = 0;

  void _onSession(SessionState session) {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    // Drop everything from the previous account before anything else.
    emit(const FavoritesState());
    if (userId != null) load();
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    emit(FavoritesState(status: FavoritesStatus.loading, lastEvent: state.lastEvent));
    try {
      final ids = await _repository.fetchFavoriteIds();
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(status: FavoritesStatus.ready, ids: ids, pending: const {}));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(status: FavoritesStatus.failure, failure: failure));
    }
  }

  /// Re-reads the saved ids while the current list stays on screen (pull to
  /// refresh; picks up changes made on another device). Skipped while a
  /// toggle is in flight so it can't undo an optimistic change. A failure
  /// keeps the current list and is reported through [FavoritesState.failure].
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    if (state.status != FavoritesStatus.ready) return load();
    if (state.pending.isNotEmpty) return;
    try {
      final ids = await _repository.fetchFavoriteIds();
      if (isClosed || _userId != userId || state.pending.isNotEmpty) return;
      emit(state.copyWith(ids: ids));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(failure: failure));
    }
  }

  /// Adds or removes [destinationId]. Ignored while a request for the same
  /// destination is in flight, or before favourites have loaded.
  Future<void> toggle(String destinationId) async {
    final userId = _userId;
    if (userId == null || state.status != FavoritesStatus.ready || state.isPending(destinationId)) return;

    final adding = !state.isFavorite(destinationId);
    final before = state.ids;
    emit(state.copyWith(
      ids: adding ? [destinationId, ...before] : [...before.where((id) => id != destinationId)],
      pending: {...state.pending, destinationId},
    ));

    try {
      if (adding) {
        await _repository.addFavorite(destinationId);
      } else {
        await _repository.removeFavorite(destinationId);
      }
      if (isClosed || _userId != userId) return;
      emit(state.copyWith(
        pending: {...state.pending}..remove(destinationId),
        lastEvent: FavoriteEvent(adding ? FavoriteChange.added : FavoriteChange.removed, destinationId, ++_serial),
      ));
    } on AppFailure catch (failure) {
      if (isClosed || _userId != userId) return;
      // Roll back only this destination; other toggles may have completed.
      final rolledBack = adding
          ? [...state.ids.where((id) => id != destinationId)]
          : [destinationId, ...state.ids.where((id) => id != destinationId)];
      emit(state.copyWith(
        ids: rolledBack,
        pending: {...state.pending}..remove(destinationId),
        lastEvent: FavoriteEvent(
          adding ? FavoriteChange.addFailed : FavoriteChange.removeFailed,
          destinationId,
          ++_serial,
          failure: failure,
        ),
      ));
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    return super.close();
  }
}
