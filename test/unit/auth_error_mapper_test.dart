import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  FailureType map(Object e) => mapAuthError(e).type;

  test('maps Supabase auth error codes', () {
    expect(
      map(
        const AuthException(
          'x',
          code: 'invalid_credentials',
          statusCode: '400',
        ),
      ),
      FailureType.invalidCredentials,
    );
    expect(
      map(const AuthException('x', code: 'email_not_confirmed')),
      FailureType.emailNotConfirmed,
    );
    expect(
      map(const AuthException('x', code: 'user_already_exists')),
      FailureType.emailAlreadyRegistered,
    );
    expect(
      map(const AuthException('x', code: 'email_exists')),
      FailureType.emailAlreadyRegistered,
    );
    expect(
      map(const AuthException('x', code: 'same_password')),
      FailureType.samePassword,
    );
    expect(
      map(const AuthException('x', code: 'over_email_send_rate_limit')),
      FailureType.rateLimited,
    );
    expect(
      map(const AuthException('x', code: 'signup_disabled')),
      FailureType.signupDisabled,
    );
    expect(
      map(const AuthException('x', code: 'session_not_found')),
      FailureType.sessionExpired,
    );
  });

  test('falls back to HTTP status when the code is unknown', () {
    expect(
      map(const AuthException('x', statusCode: '429')),
      FailureType.rateLimited,
    );
    expect(
      map(const AuthException('x', statusCode: '503')),
      FailureType.server,
    );
    expect(
      map(const AuthException('x', statusCode: '418')),
      FailureType.unknown,
    );
  });

  test('maps specialised exceptions', () {
    expect(
      map(AuthRetryableFetchException(message: 'offline')),
      FailureType.network,
    );
    expect(
      map(
        AuthWeakPasswordException(
          message: 'weak',
          statusCode: '422',
          reasons: ['length'],
        ),
      ),
      FailureType.weakPassword,
    );
    expect(map(TimeoutException('slow')), FailureType.timeout);
  });

  test('recognises raw transport errors by name', () {
    expect(
      map(Exception('SocketException: Failed host lookup')),
      FailureType.network,
    );
    expect(
      map(Exception('ClientException: XMLHttpRequest error')),
      FailureType.network,
    );
  });

  test('passes AppFailure through and keeps a debug message', () {
    const failure = AppFailure(FailureType.notFound);
    expect(mapAuthError(failure), same(failure));
    expect(
      mapAuthError(
        const AuthException('Invalid login', code: 'invalid_credentials'),
      ).debugMessage,
      contains('invalid_credentials'),
    );
  });
}
