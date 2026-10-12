import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/account_repository.dart';

/// Records deletions; fails with [failure] when set (nothing is deleted).
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.failure, this.onDelete});

  AppFailure? failure;

  /// Server-side effects of a successful deletion (e.g. clearing fakes).
  void Function()? onDelete;
  int calls = 0;
  int deleted = 0;

  @override
  Future<void> deleteMyAccount() async {
    calls++;
    final f = failure;
    if (f != null) throw f;
    deleted++;
    onDelete?.call();
  }
}
