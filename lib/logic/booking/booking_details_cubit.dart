import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../auth/auth_form_cubits.dart' show SubmitState, SubmitStatus;
import '../auth/session_cubit.dart';
import '../common/load_state.dart';

class BookingDetailsState extends Equatable {
  const BookingDetailsState({
    this.booking = const LoadState.loading(),
    this.cancellation = const SubmitState<Booking>(),
  });

  final LoadState<Booking> booking;
  final SubmitState<Booking> cancellation;

  bool get isCancelling => cancellation.isSubmitting;

  BookingDetailsState copyWith({LoadState<Booking>? booking, SubmitState<Booking>? cancellation}) =>
      BookingDetailsState(booking: booking ?? this.booking, cancellation: cancellation ?? this.cancellation);

  @override
  List<Object?> get props => [booking, cancellation];
}

/// One booking (by id from the route) and its cancellation. The booking is
/// only shown as cancelled after the database confirms it.
class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  BookingDetailsCubit(this._repository, SessionCubit session, this.bookingId) : super(const BookingDetailsState()) {
    _userId = session.state.isAuthenticated ? session.state.user?.id : null;
    _subscription = session.stream.listen(_onSession);
  }

  final BookingRepository _repository;
  final String bookingId;
  late final StreamSubscription<SessionState> _subscription;
  String? _userId;

  void _onSession(SessionState session) {
    final userId = session.isAuthenticated ? session.user?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    // Drop the previous account's data immediately; under RLS a new user
    // will get "not found" for a booking that isn't theirs.
    emit(const BookingDetailsState());
    if (userId != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    final userId = _userId;
    emit(state.copyWith(booking: const LoadState.loading()));
    try {
      final booking = await _repository.fetchBooking(bookingId);
      if (!isClosed && userId == _userId) emit(state.copyWith(booking: LoadState.success(booking)));
    } on AppFailure catch (failure) {
      if (!isClosed && userId == _userId) emit(state.copyWith(booking: LoadState.failure(failure)));
    }
  }

  /// Cancels via the backend. Ignored while a request is in flight.
  Future<void> cancel() async {
    final current = state.booking.data;
    if (current == null || state.isCancelling || current.isCancelled) return;
    final userId = _userId;
    emit(state.copyWith(cancellation: const SubmitState<Booking>(status: SubmitStatus.submitting)));
    try {
      final updated = current.withStatusFrom(await _repository.cancelBooking(bookingId));
      if (isClosed || userId != _userId) return;
      emit(BookingDetailsState(
        booking: LoadState.success(updated),
        cancellation: SubmitState<Booking>(status: SubmitStatus.success, result: updated),
      ));
    } on AppFailure catch (failure) {
      if (isClosed || userId != _userId) return;
      // The booking keeps its server state; nothing is marked cancelled.
      emit(state.copyWith(cancellation: SubmitState<Booking>(status: SubmitStatus.failure, failure: failure)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
