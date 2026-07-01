import 'package:first_app/core/reposatories/auth_reposatory.dart';
import 'package:first_app/logic/Blocs/Register/register_event.dart';
import 'package:first_app/logic/Blocs/Register/register_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;

class RegisterBloc extends bloc.Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterInitial());
  final AuthRepository _authReposatory = AuthRepository();
  Future<void> onRegisterSubmitted(
      RegisterSubmitted event, bloc.Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      await _authReposatory.register(
        name: event.name,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterFailure(error: e.toString()));
    }
  }
}
