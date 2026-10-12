import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import 'supabase_auth_repository.dart';

/// Translates Supabase database/storage/transport errors into [AppFailure].
///
/// Raw PostgREST messages never reach the UI; they're kept in
/// [AppFailure.debugMessage] for logs.
AppFailure mapSupabaseError(Object error) {
  if (error is AppFailure) return error;
  if (error is AuthException) return mapAuthError(error);
  if (error is TimeoutException) return AppFailure(FailureType.timeout, debugMessage: error.toString());
  if (error is FormatException || error is TypeError) {
    return AppFailure(FailureType.invalidData, debugMessage: error.toString());
  }
  if (error is PostgrestException) {
    final code = error.code ?? '';
    final type = switch (code) {
      // Row Level Security / missing GRANT.
      '42501' || '403' => FailureType.permissionDenied,
      // JWT expired or invalid.
      'PGRST301' || 'PGRST303' || '401' => FailureType.sessionExpired,
      // `.single()` matched no rows.
      'PGRST116' || '404' => FailureType.notFound,
      // Statement timeout.
      '57014' => FailureType.timeout,
      // Undefined table/function/column — schema not (fully) applied.
      'PGRST205' || 'PGRST202' || 'PGRST204' || '42P01' || '42883' || '42703' => FailureType.server,
      '429' => FailureType.rateLimited,
      _ when code.startsWith('5') || code.startsWith('PGRST0') => FailureType.server,
      _ => FailureType.unknown,
    };
    return AppFailure(
      type,
      debugMessage: '[$code] ${error.message}${error.hint == null ? '' : ' (hint: ${error.hint})'}',
    );
  }
  if (error is StorageException) {
    final type = switch (error.statusCode) {
      '401' => FailureType.sessionExpired,
      '403' => FailureType.permissionDenied,
      '404' => FailureType.notFound,
      _ => FailureType.server,
    };
    return AppFailure(
      type,
      debugMessage: '[storage ${error.statusCode}] ${error.message}',
    );
  }
  // Raw transport errors (SocketException on IO, ClientException on web),
  // matched by name to keep this file platform-neutral.
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection closed') ||
      text.contains('HandshakeException')) {
    return AppFailure(FailureType.network, debugMessage: text);
  }
  return AppFailure(FailureType.unknown, debugMessage: text);
}
