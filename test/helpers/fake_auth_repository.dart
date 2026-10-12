import 'dart:async';

import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/data/repositories/auth_repository.dart';

const testUser = AppUser(
  id: 'user-1',
  email: 'traveller@example.com',
  fullName: 'Sara Ali',
  emailConfirmed: true,
);

/// In-memory [AuthRepository] for tests. Behaves like the real backend at
/// the contract level: emits auth changes and throws [AppFailure]s.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedInAs}) : _user = signedInAs;

  final _changes = StreamController<AuthChangeEvent>.broadcast();
  AppUser? _user;

  /// Next failure to throw from any call (consumed once).
  AppFailure? nextFailure;
  SignUpOutcome signUpOutcome = SignUpOutcome.confirmationRequired;
  SignOutOutcome signOutOutcome = SignOutOutcome.signedOut;

  final calls = <String>[];

  void _maybeFail() {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
  }

  /// Simulates a server-side session end (e.g. refresh token revoked).
  void expireSession() {
    _user = null;
    _changes.add(const AuthChangeEvent(AuthChange.signedOut, null));
  }

  /// Simulates a different account becoming the active session.
  void switchTo(AppUser user) {
    _user = user;
    _changes.add(AuthChangeEvent(AuthChange.signedIn, user));
  }

  void emitPasswordRecovery() {
    _user ??= testUser;
    _changes.add(AuthChangeEvent(AuthChange.passwordRecovery, _user));
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AuthChangeEvent> get changes => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    _maybeFail();
    _user = AppUser(id: 'user-1', email: email, emailConfirmed: true);
    _changes.add(AuthChangeEvent(AuthChange.signedIn, _user));
  }

  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    calls.add('signUp:$email');
    _maybeFail();
    if (signUpOutcome == SignUpOutcome.signedIn) {
      _user = AppUser(id: 'user-2', email: email, fullName: fullName);
      _changes.add(AuthChangeEvent(AuthChange.signedIn, _user));
    }
    return signUpOutcome;
  }

  @override
  Future<void> resendConfirmation(String email) async {
    calls.add('resend:$email');
    _maybeFail();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    _maybeFail();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('updatePassword');
    _maybeFail();
  }

  @override
  Future<SignOutOutcome> signOut() async {
    calls.add('signOut');
    _maybeFail();
    _user = null;
    _changes.add(const AuthChangeEvent(AuthChange.signedOut, null));
    return signOutOutcome;
  }

  Future<void> dispose() => _changes.close();
}
