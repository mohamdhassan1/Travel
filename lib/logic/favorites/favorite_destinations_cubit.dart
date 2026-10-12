import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../common/load_state.dart';
import 'favorites_cubit.dart';

/// Card data for the Favourites screen, kept in sync with [FavoritesCubit]:
/// removals disappear immediately (and reappear on rollback) without a new
/// request; newly added ids are fetched.
class FavoriteDestinationsCubit extends Cubit<LoadState<List<DestinationSummary>>> {
  FavoriteDestinationsCubit(this._catalog, this._favorites) : super(const LoadState.loading()) {
    _subscription = _favorites.stream.listen(_sync);
    _sync(_favorites.state);
  }

  final CatalogRepository _catalog;
  final FavoritesCubit _favorites;
  late final StreamSubscription<FavoritesState> _subscription;

  /// Every summary fetched so far, so rollbacks don't need a refetch.
  final _cache = <String, DestinationSummary>{};
  List<String>? _requestedIds;

  Future<void> _sync(FavoritesState favorites) async {
    switch (favorites.status) {
      case FavoritesStatus.signedOut:
      case FavoritesStatus.loading:
        if (state.status != LoadStatus.loading) emit(const LoadState.loading());
      case FavoritesStatus.failure:
        emit(LoadState.failure(favorites.failure ?? const AppFailure(FailureType.unknown)));
      case FavoritesStatus.ready:
        await _show(favorites.ids);
    }
  }

  Future<void> _show(List<String> ids) async {
    if (ids.isEmpty) {
      emit(const LoadState.empty());
      return;
    }
    final missing = ids.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      _requestedIds = ids;
      if (state.status != LoadStatus.success) emit(const LoadState.loading());
      try {
        for (final d in await _catalog.fetchDestinationsByIds(missing)) {
          _cache[d.id] = d;
        }
      } on AppFailure catch (failure) {
        if (!isClosed && identical(_requestedIds, ids)) emit(LoadState.failure(failure));
        return;
      }
      // A newer favourites state superseded this one while we were loading.
      if (isClosed || !identical(_requestedIds, ids)) return;
    }
    // Ids whose destination no longer exists / is unpublished are skipped.
    final items = [
      for (final id in ids)
        if (_cache[id] != null) _cache[id]!
    ];
    emit(items.isEmpty ? const LoadState.empty() : LoadState.success(items));
  }

  /// Retry after a failure: reload favourites if they failed, else the cards.
  Future<void> retry() async {
    if (_favorites.state.status == FavoritesStatus.ready) {
      await _show(_favorites.state.ids);
    } else {
      await _favorites.load();
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
