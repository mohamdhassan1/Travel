import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  FailureType map(Object e) => mapSupabaseError(e).type;
  PostgrestException pg(String code) => PostgrestException(message: 'raw db message', code: code);

  test('RLS / grant failures become permissionDenied', () {
    expect(map(pg('42501')), FailureType.permissionDenied);
    expect(map(pg('403')), FailureType.permissionDenied);
  });

  test('expired or invalid JWTs become sessionExpired', () {
    expect(map(pg('PGRST301')), FailureType.sessionExpired);
    expect(map(pg('401')), FailureType.sessionExpired);
  });

  test(
    'a missing table (schema not applied) is a server problem, not unknown',
    () {
      expect(map(pg('PGRST205')), FailureType.server);
      expect(map(pg('42P01')), FailureType.server);
      expect(map(pg('503')), FailureType.server);
    },
  );

  test('other mappings', () {
    expect(map(pg('PGRST116')), FailureType.notFound);
    expect(map(pg('57014')), FailureType.timeout);
    expect(map(pg('429')), FailureType.rateLimited);
    expect(map(pg('XX999')), FailureType.unknown);
  });

  test('transport, timeout and malformed-data errors', () {
    expect(
      map(Exception('ClientException: Failed host lookup: x.supabase.co')),
      FailureType.network,
    );
    expect(map(TimeoutException('slow')), FailureType.timeout);
    expect(map(const FormatException('bad row')), FailureType.invalidData);
  });

  test('storage errors', () {
    expect(
      map(const StorageException('denied', statusCode: '403')),
      FailureType.permissionDenied,
    );
    expect(
      map(const StorageException('missing', statusCode: '404')),
      FailureType.notFound,
    );
  });

  test('auth errors are delegated to the auth mapper', () {
    expect(
      map(const AuthException('expired', code: 'session_not_found')),
      FailureType.sessionExpired,
    );
  });

  test('raw database text stays in the debug message only', () {
    final failure = mapSupabaseError(pg('42501'));
    expect(failure.debugMessage, contains('raw db message'));
    expect(failure.debugMessage, contains('42501'));
  });
}
