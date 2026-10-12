import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../auth/session_cubit.dart';
import '../common/load_state.dart';

/// The signed-in user's bookings. Reloads when a different user signs in and
/// clears on sign-out, so one account's bookings are never shown to another.
class MyBookingsCubit extends Cubit<LoadState<List<Booking>>> {
  MyBookingsCubit(this._repository, SessionCubit session, {Stream<Object?>? changes})
      : super(const LoadState.loading()) {
    _userId = session.state.isAuthenticated ? session.state.user?.id : null;
    _subscription = session.stream.listen(_onSession);
    // A booking was created or cancelled elsewhere: refresh quietly.
    _changesSubscription = changes?.listen((_) => load());
  }

  final BookingRepository _repository;
  late final StreamSubscription<SessionState> _subscription;
  StreamSubscription<Object?>? _changesSubscription;
  String? _userId;
  int _generation = 0;

  void _onSession(SessionState session) {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    // Invalidate any request still in flight for the previous account.
    _generation++;
    emit(const LoadState.loading());
    if (userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    final generation = ++_generation;
    if (state.status != LoadStatus.success) emit(const LoadState.loading());
    try {
      final bookings = await _repository.fetchMyBookings();
      // Ignore results that belong to an earlier request / previous user.
      if (isClosed || generation != _generation) return;
      emit(bookings.isEmpty ? const LoadState.empty() : LoadState.success(bookings));
    } on AppFailure catch (failure) {
      if (!isClosed && generation == _generation) emit(LoadState.failure(failure));
    }
  }

  /// Replaces one booking after a server-confirmed change (e.g. cancellation).
  void applyServerUpdate(Booking updated) {
    final list = state.data;
    if (list == null) return;
    emit(LoadState.success([for (final b in list) b.id == updated.id ? b.withStatusFrom(updated) : b]));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _changesSubscription?.cancel();
    return super.close();
  }
}
