import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';

enum CatalogStatus { loading, ready, failure }

class CatalogState extends Equatable {
  const CatalogState({
    this.status = CatalogStatus.loading,
    this.categories = const [],
    this.destinations = const [],
    this.failure,
    this.refreshing = false,
  });

  final CatalogStatus status;
  final List<TravelCategory> categories;

  /// Published destinations, featured first (server order).
  final List<DestinationSummary> destinations;
  final AppFailure? failure;

  /// A background reload while the current catalog stays on screen.
  final bool refreshing;

  bool get isReady => status == CatalogStatus.ready;
  List<DestinationSummary> get featured => [
        for (final d in destinations)
          if (d.isFeatured) d
      ];

  TravelCategory? category(String id) => categories.where((c) => c.id == id).firstOrNull;
  DestinationSummary? destination(String id) => destinations.where((d) => d.id == id).firstOrNull;

  @override
  List<Object?> get props => [status, categories, destinations, failure, refreshing];
}

/// The public catalog (categories + destination summaries), loaded once and
/// shared by Home, Explore and Saved — one request instead of one per screen.
/// It isn't user data, so it survives sign-out.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._catalog) : super(const CatalogState());

  final CatalogRepository _catalog;
  Future<void>? _inFlight;

  /// First load (no-op if already loaded or loading).
  Future<void> ensureLoaded() => state.isReady ? Future.value() : load();

  /// (Re)loads. Concurrent calls share one request. Existing data stays
  /// visible during a refresh; a failed refresh keeps it and reports.
  Future<void> load() => _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    final hadData = state.isReady;
    emit(hadData
        ? CatalogState(
            status: CatalogStatus.ready,
            categories: state.categories,
            destinations: state.destinations,
            refreshing: true,
          )
        : const CatalogState());
    try {
      final (categories, destinations) = await (_catalog.fetchCategories(), _catalog.fetchDestinations()).wait;
      if (isClosed) return;
      emit(CatalogState(status: CatalogStatus.ready, categories: categories, destinations: destinations));
    } on ParallelWaitError<(List<TravelCategory>?, List<DestinationSummary>?), (AsyncError?, AsyncError?)> catch (e) {
      final error = e.errors.$1?.error ?? e.errors.$2?.error;
      _fail(error is AppFailure ? error : AppFailure(FailureType.unknown, debugMessage: '$error'), hadData);
    } on AppFailure catch (failure) {
      _fail(failure, hadData);
    }
  }

  void _fail(AppFailure failure, bool hadData) {
    if (isClosed) return;
    emit(hadData
        ? CatalogState(
            status: CatalogStatus.ready,
            categories: state.categories,
            destinations: state.destinations,
            failure: failure,
          )
        : CatalogState(status: CatalogStatus.failure, failure: failure));
  }
}
