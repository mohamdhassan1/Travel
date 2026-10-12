import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState extends Equatable {
  const SessionState({
    this.status = SessionStatus.unknown,
    this.user,
    this.passwordRecovery = false,
    this.endedUnexpectedly = false,
  });

  final SessionStatus status;
  final AppUser? user;

  /// The user arrived via a password-reset link and must set a new password.
  final bool passwordRecovery;

  /// The session ended without the user signing out (expired / revoked).
  final bool endedUnexpectedly;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  List<Object?> get props => [
        status,
        user,
        passwordRecovery,
        endedUnexpectedly,
      ];
}

/// App-wide source of truth for "who is signed in". Restores the persisted
/// session at startup and follows auth changes (sign-in via deep link,
/// token refresh failure, sign-out on another code path).
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth) : super(const SessionState()) {
    _subscription = _auth.changes.listen(_onChange);
    final user = _auth.currentUser;
    emit(
      SessionState(
        status: user == null ? SessionStatus.unauthenticated : SessionStatus.authenticated,
        user: user,
      ),
    );
  }

  final AuthRepository _auth;
  late final StreamSubscription<AuthChangeEvent> _subscription;
  bool _userInitiatedSignOut = false;
  final _beforeSignOut = <Future<void> Function()>[];

  /// Work that needs the still-valid session right before a user-initiated
  /// sign-out (e.g. unregistering this device's push token). Failures and
  /// slow hooks never block signing out.
  void addBeforeSignOutHook(Future<void> Function() hook) => _beforeSignOut.add(hook);

  void _onChange(AuthChangeEvent event) {
    switch (event.change) {
      case AuthChange.signedIn:
      case AuthChange.userUpdated:
        emit(
          SessionState(
            status: SessionStatus.authenticated,
            user: event.user ?? state.user,
            passwordRecovery: state.passwordRecovery,
          ),
        );
      case AuthChange.passwordRecovery:
        emit(
          SessionState(
            status: SessionStatus.authenticated,
            user: event.user ?? state.user,
            passwordRecovery: true,
          ),
        );
      case AuthChange.signedOut:
        final unexpected = state.isAuthenticated && !_userInitiatedSignOut;
        _userInitiatedSignOut = false;
        emit(
          SessionState(
            status: SessionStatus.unauthenticated,
            endedUnexpectedly: unexpected,
          ),
        );
    }
  }

  /// Signs out; the resulting `signedOut` event updates [state].
  Future<SignOutOutcome> signOut() async {
    for (final hook in _beforeSignOut) {
      try {
        await hook().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best effort only.
      }
    }
    _userInitiatedSignOut = true;
    try {
      return await _auth.signOut();
    } catch (_) {
      _userInitiatedSignOut = false;
      rethrow;
    }
  }

  /// Permanently deletes the account through [deleteOnServer], then clears
  /// the local session. Throws the server's failure — and leaves the user
  /// signed in, with nothing changed — if the deletion is refused.
  ///
  /// The before-sign-out hooks don't run: the server deletes this device's
  /// push token with the account, and the `signedOut` event clears local
  /// reminders as on any sign-out.
  Future<void> deleteAccount(Future<void> Function() deleteOnServer) async {
    await deleteOnServer();
    // The user no longer exists, so revoking the session server-side may
    // fail; the local session is cleared either way.
    _userInitiatedSignOut = true;
    try {
      await _auth.signOut();
    } catch (_) {
      _userInitiatedSignOut = false;
      rethrow;
    }
  }

  void completePasswordRecovery() {
    if (state.passwordRecovery) {
      emit(
        SessionState(
          status: state.status,
          user: _auth.currentUser ?? state.user,
        ),
      );
    }
  }

  /// Clears the "you were signed out" notice after it has been shown.
  void acknowledgeSessionEnded() {
    if (state.endedUnexpectedly) emit(SessionState(status: state.status, user: state.user));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
