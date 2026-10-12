import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/repositories/weather_repository.dart';
import '../common/load_state.dart';

/// Weather for one destination. Independent from the destination itself, so
/// a weather failure never blocks the details page.
class WeatherCubit extends Cubit<LoadState<WeatherReport>> {
  WeatherCubit(this._weather, this.latitude, this.longitude) : super(const LoadState.loading());

  final WeatherRepository _weather;
  final double latitude;
  final double longitude;

  Future<void> load() async {
    if (state.status != LoadStatus.loading) emit(const LoadState.loading());
    try {
      final report = await _weather.fetch(latitude, longitude);
      if (!isClosed) emit(LoadState.success(report));
    } on AppFailure catch (failure) {
      if (!isClosed) emit(LoadState.failure(failure));
    }
  }
}
