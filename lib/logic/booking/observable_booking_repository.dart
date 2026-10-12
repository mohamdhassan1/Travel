import 'dart:async';

import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';

/// A [BookingRepository] that announces server-confirmed changes (a booking
/// created or cancelled), so app-wide views — Home's next trip, the Trips
/// tab, profile statistics — refresh without polling.
class ObservableBookingRepository implements BookingRepository {
  ObservableBookingRepository(this._inner);

  final BookingRepository _inner;
  final _changes = StreamController<Booking>.broadcast();

  /// Emits the booking the server returned after a create or cancel.
  Stream<Booking> get changes => _changes.stream;

  @override
  Future<Booking> createBooking(BookingRequest request) async {
    final booking = await _inner.createBooking(request);
    _changes.add(booking);
    return booking;
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    final booking = await _inner.cancelBooking(id);
    _changes.add(booking);
    return booking;
  }

  @override
  Future<List<Booking>> fetchMyBookings() => _inner.fetchMyBookings();

  @override
  Future<Booking> fetchBooking(String id) => _inner.fetchBooking(id);

  Future<void> dispose() => _changes.close();
}
