import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../common/load_state.dart';

class DestinationDetailsState extends Equatable {
  const DestinationDetailsState({
    this.destination = const LoadState.loading(),
    this.packages = const LoadState.loading(),
  });

  final LoadState<DestinationDetails> destination;

  /// Loaded independently: a packages failure doesn't hide the destination.
  final LoadState<List<TravelPackage>> packages;

  DestinationDetailsState copyWith({
    LoadState<DestinationDetails>? destination,
    LoadState<List<TravelPackage>>? packages,
  }) =>
      DestinationDetailsState(destination: destination ?? this.destination, packages: packages ?? this.packages);

  @override
  List<Object?> get props => [destination, packages];
}

/// Loads one destination (by id from the route) and its packages, in parallel.
class DestinationDetailsCubit extends Cubit<DestinationDetailsState> {
  DestinationDetailsCubit(this._catalog, this.destinationId) : super(const DestinationDetailsState());

  final CatalogRepository _catalog;
  final String destinationId;

  Future<void> load() async {
    emit(const DestinationDetailsState());
    await Future.wait([_loadDestination(), loadPackages()]);
  }

  Future<void> _loadDestination() async {
    try {
      final destination = await _catalog.fetchDestination(destinationId);
      if (!isClosed) emit(state.copyWith(destination: LoadState.success(destination)));
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(destination: LoadState.failure(failure)));
    }
  }

  /// Also used to retry just the packages section.
  Future<void> loadPackages() async {
    if (state.packages.status != LoadStatus.loading) {
      emit(state.copyWith(packages: const LoadState.loading()));
    }
    try {
      final packages = await _catalog.fetchPackages(destinationId);
      if (isClosed) return;
      emit(state.copyWith(packages: packages.isEmpty ? const LoadState.empty() : LoadState.success(packages)));
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(packages: LoadState.failure(failure)));
    }
  }
}
