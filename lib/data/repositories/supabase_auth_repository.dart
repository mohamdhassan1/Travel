import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth, {required String redirectUrl}) : _redirectUrl = redirectUrl;

  final sb.GoTrueClient _auth;
  final String _redirectUrl;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AuthChangeEvent> get changes => _auth.onAuthStateChange
      .map((state) {
        final change = switch (state.event) {
          sb.AuthChangeEvent.signedIn => AuthChange.signedIn,
          sb.AuthChangeEvent.signedOut => AuthChange.signedOut,
          sb.AuthChangeEvent.passwordRecovery => AuthChange.passwordRecovery,
          sb.AuthChangeEvent.userUpdated => AuthChange.userUpdated,
          // initialSession / tokenRefreshed / MFA events don't change routing.
          _ => null,
        };
        return change == null ? null : AuthChangeEvent(change, _toAppUser(state.session?.user));
      })
      .where((e) => e != null)
      .cast<AuthChangeEvent>()
      .handleError(
        (Object e, StackTrace s) => AppLogger.error('Auth stream error', error: e, stackTrace: s),
      );

  @override
  Future<void> signIn({required String email, required String password}) => _guard(
        () => _auth.signInWithPassword(email: email.trim(), password: password),
      );

  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final response = await _auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim()},
          emailRedirectTo: _redirectUrl,
        );
        return response.session != null ? SignUpOutcome.signedIn : SignUpOutcome.confirmationRequired;
      });

  @override
  Future<void> resendConfirmation(String email) => _guard(
        () => _auth.resend(
          type: sb.OtpType.signup,
          email: email.trim(),
          emailRedirectTo: _redirectUrl,
        ),
      );

  @override
  Future<void> sendPasswordReset(String email) => _guard(
        () => _auth.resetPasswordForEmail(email.trim(), redirectTo: _redirectUrl),
      );

  @override
  Future<void> updatePassword(String newPassword) =>
      _guard(() => _auth.updateUser(sb.UserAttributes(password: newPassword)));

  @override
  Future<SignOutOutcome> signOut() async {
    try {
      await _auth.signOut();
      return SignOutOutcome.signedOut;
    } catch (error, stack) {
      final failure = mapAuthError(error);
      if (failure.type != FailureType.network && failure.type != FailureType.timeout) {
        AppLogger.error('Sign-out failed', error: error, stackTrace: stack);
      }
      // gotrue clears the local session *before* calling the server, so the
      // device is signed out even though revoking the refresh token failed.
      return SignOutOutcome.signedOutLocally;
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stack) {
      final failure = mapAuthError(error);
      if (failure.type == FailureType.unknown || failure.type == FailureType.server) {
        AppLogger.error('Auth request failed', error: error, stackTrace: stack);
      }
      throw failure;
    }
  }

  static AppUser? _toAppUser(sb.User? user) {
    if (user == null) return null;
    final name = user.userMetadata?['full_name'];
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: name is String ? name : null,
      emailConfirmed: user.emailConfirmedAt != null,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }
}

/// Translates Supabase Auth / transport errors into [AppFailure].
///
/// Prefers the stable `code` returned by the Auth server; falls back to HTTP
/// status codes for older servers.
AppFailure mapAuthError(Object error) {
  if (error is AppFailure) return error;
  if (error is TimeoutException) {
    return AppFailure(FailureType.timeout, debugMessage: error.toString());
  }
  if (error is sb.AuthRetryableFetchException) {
    return AppFailure(FailureType.network, debugMessage: error.message);
  }
  if (error is sb.AuthWeakPasswordException) {
    return AppFailure(FailureType.weakPassword, debugMessage: error.message);
  }
  if (error is sb.AuthSessionMissingException) {
    return AppFailure(FailureType.sessionExpired, debugMessage: error.message);
  }
  if (error is sb.AuthException) {
    final type = switch (error.code) {
      'invalid_credentials' => FailureType.invalidCredentials,
      'email_not_confirmed' => FailureType.emailNotConfirmed,
      'user_already_exists' || 'email_exists' => FailureType.emailAlreadyRegistered,
      'weak_password' => FailureType.weakPassword,
      'same_password' => FailureType.samePassword,
      'signup_disabled' || 'email_provider_disabled' => FailureType.signupDisabled,
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' ||
      'over_sms_send_rate_limit' =>
        FailureType.rateLimited,
      'session_not_found' || 'session_expired' || 'refresh_token_not_found' || 'bad_jwt' => FailureType.sessionExpired,
      'user_not_found' => FailureType.notFound,
      _ => switch (error.statusCode) {
          '429' => FailureType.rateLimited,
          '401' || '403' => FailureType.sessionExpired,
          final String s when s.startsWith('5') => FailureType.server,
          _ => FailureType.unknown,
        },
    };
    return AppFailure(
      type,
      debugMessage: '[${error.code ?? error.statusCode}] ${error.message}',
    );
  }
  // Raw transport errors (SocketException on IO, ClientException on web)
  // matched by name so this file stays platform-neutral.
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException') || text.contains('Failed host lookup')) {
    return AppFailure(FailureType.network, debugMessage: text);
  }
  return AppFailure(FailureType.unknown, debugMessage: text);
}
