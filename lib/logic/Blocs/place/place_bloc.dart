import 'package:first_app/Data/place_model.dart';
import 'package:first_app/core/reposatories/plase_reposatory.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'place_event.dart';
part 'place_state.dart';

class PlaceBloc extends Bloc<PlaceEvent, PlaceState> {
  final PlaceRepository _repo;

  PlaceBloc(this._repo) : super(PlaceInitial()) {
    on<LoadPlaces>((event, emit) async {
      emit(PlaceLoading());
      try {
        final places = await _repo.getPlaces();
        emit(PlaceLoaded(places));
      } catch (e) {
        emit(PlaceError(e.toString()));
      }
    });
  }
}
