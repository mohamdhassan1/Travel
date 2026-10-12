import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/auth_repository.dart';

enum SubmitStatus { idle, submitting, success, failure }

/// Shared state for one-shot form submissions.
class SubmitState<T> extends Equatable {
  const SubmitState({
    this.status = SubmitStatus.idle,
    this.result,
    this.failure,
  });

  final SubmitStatus status;
  final T? result;
  final AppFailure? failure;

  bool get isSubmitting => status == SubmitStatus.submitting;

  @override
  List<Object?> get props => [status, result, failure];
}

/// Runs [action], reporting submitting → success/failure. Ignores re-entry
/// while a request is in flight (prevents double taps / duplicate requests).
mixin _Submitter<T> on Cubit<SubmitState<T>> {
  Future<void> run(Future<T> Function() action) async {
    if (state.isSubmitting) return;
    emit(SubmitState<T>(status: SubmitStatus.submitting));
    try {
      final result = await action();
      if (!isClosed) emit(SubmitState<T>(status: SubmitStatus.success, result: result));
    } on AppFailure catch (failure) {
      if (!isClosed) emit(SubmitState<T>(status: SubmitStatus.failure, failure: failure));
    } catch (error, stack) {
      AppLogger.error(
        'Unexpected submit error',
        error: error,
        stackTrace: stack,
      );
      if (!isClosed) {
        emit(
          SubmitState<T>(
            status: SubmitStatus.failure,
            failure: AppFailure(
              FailureType.unknown,
              debugMessage: error.toString(),
            ),
          ),
        );
      }
    }
  }
}

class LoginCubit extends Cubit<SubmitState<void>> with _Submitter<void> {
  LoginCubit(this._auth) : super(const SubmitState());
  final AuthRepository _auth;

  Future<void> submit({required String email, required String password}) =>
      run(() => _auth.signIn(email: email, password: password));
}

class RegisterCubit extends Cubit<SubmitState<SignUpOutcome>> with _Submitter<SignUpOutcome> {
  RegisterCubit(this._auth) : super(const SubmitState());
  final AuthRepository _auth;

  Future<void> submit({
    required String fullName,
    required String email,
    required String password,
  }) =>
      run(
        () => _auth.signUp(fullName: fullName, email: email, password: password),
      );
}

class PasswordResetRequestCubit extends Cubit<SubmitState<void>> with _Submitter<void> {
  PasswordResetRequestCubit(this._auth) : super(const SubmitState());
  final AuthRepository _auth;

  Future<void> submit(String email) => run(() => _auth.sendPasswordReset(email));
}

class NewPasswordCubit extends Cubit<SubmitState<void>> with _Submitter<void> {
  NewPasswordCubit(this._auth) : super(const SubmitState());
  final AuthRepository _auth;

  Future<void> submit(String password) => run(() => _auth.updatePassword(password));
}

/// Resending is rate-limited server-side; the UI adds a cooldown on top
/// (see `ResendCooldownButton`).
class ResendConfirmationCubit extends Cubit<SubmitState<void>> with _Submitter<void> {
  ResendConfirmationCubit(this._auth) : super(const SubmitState());
  final AuthRepository _auth;

  Future<void> submit(String email) => run(() => _auth.resendConfirmation(email));
}
