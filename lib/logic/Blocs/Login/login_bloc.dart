import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());

      try {
        UserCredential userCredential =
            await _firebaseAuth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        emit(
          LoginSuccess(
            userCredential.user!.uid,
          ),
        );
      } on FirebaseAuthException catch (e) {
        emit(
          LoginFailure(
            e.message ?? "Login failed",
          ),
        );
      } catch (e) {
        emit(
          LoginFailure(
            e.toString(),
          ),
        );
      }
    });
  }
}
