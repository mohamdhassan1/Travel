import 'package:equatable/equatable.dart';

import '../../core/errors/app_failure.dart';

enum LoadStatus { loading, success, empty, failure }

/// State for screens that load remote data: loading → success | empty | failure.
class LoadState<T> extends Equatable {
  const LoadState._(this.status, {this.data, this.failure});

  const LoadState.loading() : this._(LoadStatus.loading);
  const LoadState.success(T data) : this._(LoadStatus.success, data: data);
  const LoadState.empty() : this._(LoadStatus.empty);
  const LoadState.failure(AppFailure failure) : this._(LoadStatus.failure, failure: failure);

  final LoadStatus status;
  final T? data;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, data, failure];
}
