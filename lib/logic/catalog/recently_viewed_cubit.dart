import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/catalog_repository.dart' show isUuid;
import '../../data/repositories/recently_viewed_store.dart';
import '../auth/session_cubit.dart';

/// Ids of destinations the signed-in user opened recently on this device.
/// Read from storage once per sign-in; switches with the account.
class RecentlyViewedCubit extends Cubit<List<String>> {
  RecentlyViewedCubit(this._store, SessionCubit session) : super(const []) {
    _subscription = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final RecentlyViewedStore _store;
  late final StreamSubscription<SessionState> _subscription;
  String? _userId;

  void _onSession(SessionState session) {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    emit(userId == null ? const [] : _store.read(userId));
  }

  Future<void> record(String destinationId) async {
    final userId = _userId;
    if (userId == null || !isUuid(destinationId)) return;
    if (state.isNotEmpty && state.first == destinationId) return;
    final ids = await _store.record(userId, destinationId);
    if (!isClosed && userId == _userId) emit(ids);
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) return;
    await _store.clear(userId);
    if (!isClosed && userId == _userId) emit(const []);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
