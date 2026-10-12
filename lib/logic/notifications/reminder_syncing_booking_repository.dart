import 'dart:async';

import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import 'trip_reminder_scheduler.dart';

/// A [BookingRepository] that keeps local trip reminders in step with what
/// the server returned: a new booking schedules one, a cancellation removes
/// it, and reading the list reconciles them all. Reminders follow results
/// from Supabase only — never optimistic UI state.
///
/// Scheduling happens in the background and never fails the booking call.
class ReminderSyncingBookingRepository implements BookingRepository {
  ReminderSyncingBookingRepository(this._inner, this._reminders, {required String? Function() currentUserId})
      : _currentUserId = currentUserId;

  final BookingRepository _inner;
  final TripReminderScheduler _reminders;
  final String? Function() _currentUserId;

  @override
  Future<Booking> createBooking(BookingRequest request) async {
    final user = _currentUserId();
    final booking = await _inner.createBooking(request);
    if (user != null) unawaited(_reminders.bookingChanged(user, booking));
    return booking;
  }

  @override
  Future<List<Booking>> fetchMyBookings() async {
    final user = _currentUserId();
    final bookings = await _inner.fetchMyBookings();
    if (user != null) unawaited(_reminders.syncAll(user, bookings));
    return bookings;
  }

  @override
  Future<Booking> fetchBooking(String id) async {
    final user = _currentUserId();
    final booking = await _inner.fetchBooking(id);
    if (user != null) unawaited(_reminders.bookingChanged(user, booking));
    return booking;
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    final user = _currentUserId();
    final booking = await _inner.cancelBooking(id);
    if (user != null) unawaited(_reminders.bookingChanged(user, booking));
    return booking;
  }
}
