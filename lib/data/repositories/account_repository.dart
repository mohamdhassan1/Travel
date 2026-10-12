import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import 'profile_repository.dart';
import 'supabase_error_mapper.dart';

/// Permanent deletion of the signed-in user's account. Throws `AppFailure`.
abstract interface class AccountRepository {
  /// Deletes the user's stored files, then the account itself. On success
  /// the server has removed the user and every row they own (profile,
  /// bookings, favourites, notifications, device tokens). Nothing is
  /// deleted if this throws.
  Future<void> deleteMyAccount();
}

class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository(this._client, {this.timeout = const Duration(seconds: 20)});

  final SupabaseClient _client;
  final Duration timeout;

  @override
  Future<void> deleteMyAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AppFailure(FailureType.sessionExpired, debugMessage: 'No signed-in user');

      // 1. Files: the database can't delete storage objects itself, so the
      //    owner removes their own folder (owner-delete policy) first.
      final bucket = _client.storage.from(SupabaseProfileRepository.bucket);
      final files = await bucket.list(path: userId).timeout(timeout);
      final paths = [for (final f in files) '$userId/${f.name}'];
      if (paths.isNotEmpty) await bucket.remove(paths).timeout(timeout);

      // 2. The account: `delete_my_account` refuses while any file remains,
      //    then removes the auth user; owned rows cascade.
      await _client.rpc<dynamic>('delete_my_account').timeout(timeout);
    } catch (error, stack) {
      final failure = mapAccountError(error);
      AppLogger.error('Account: deletion failed (${failure.type.name})', error: failure.debugMessage, stackTrace: stack);
      throw failure;
    }
  }
}

AppFailure mapAccountError(Object error) {
  if (error is PostgrestException && error.code == 'P0001' && error.message == 'avatar_cleanup_required') {
    // The photo couldn't be removed; retrying usually succeeds.
    return AppFailure(FailureType.server, debugMessage: '[${error.code}] ${error.message}');
  }
  return mapSupabaseError(error);
}
