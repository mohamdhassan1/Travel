import '../models/app_user.dart';

/// Auth lifecycle events the app reacts to.
enum AuthChange {
  signedIn,
  signedOut,

  /// The user opened a password-recovery link and holds a recovery session.
  passwordRecovery,
  userUpdated,
}

class AuthChangeEvent {
  const AuthChangeEvent(this.change, this.user);
  final AuthChange change;
  final AppUser? user;
}

/// Outcome of a sign-up request.
enum SignUpOutcome {
  /// Account created and a session is active (email confirmation disabled).
  signedIn,

  /// A confirmation email was sent (or the address already exists — the
  /// server intentionally doesn't reveal which).
  confirmationRequired,
}

enum SignOutOutcome {
  /// Server session revoked and local session cleared.
  signedOut,

  /// Server unreachable: the local session was cleared anyway.
  signedOutLocally,
}

/// Authentication contract. All methods throw `AppFailure` on error.
abstract interface class AuthRepository {
  AppUser? get currentUser;

  Stream<AuthChangeEvent> get changes;

  Future<void> signIn({required String email, required String password});

  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> resendConfirmation(String email);

  Future<void> sendPasswordReset(String email);

  /// Sets a new password for the current (typically recovery) session.
  Future<void> updatePassword(String newPassword);

  Future<SignOutOutcome> signOut();
}
