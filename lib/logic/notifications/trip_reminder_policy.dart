import 'dart:convert';

import '../../core/utils/ids.dart';
import '../../data/models/booking.dart';

/// When and how a local trip reminder is shown. Pure Dart so the rules can be
/// tested exhaustively.
///
/// Bookings store only a travel **date** (`date` column, no time of day), so
/// the reminder is date-based: **09:00 device-local time on the day before
/// the travel date.** It is only scheduled for confirmed bookings whose
/// reminder moment is still in the future; otherwise (cancelled, past, or
/// booked after 09:00 the day before) there is no reminder.
abstract final class TripReminderPolicy {
  static const reminderHour = 9;

  /// The reminder as an absolute **UTC instant**, or `null` if none should
  /// be scheduled. [now] is any [DateTime] (compared as an instant).
  ///
  /// 09:00 is device-local wall-clock time *on the reminder date*: the UTC
  /// offset in force on that date is used (so a DST change between today and
  /// the reminder is handled). [utcOffsetAt] defaults to the device's time
  /// zone; tests pass fixed zones.
  static DateTime? reminderTime(
    Booking booking,
    DateTime now, {
    Duration Function(DateTime localWallClock)? utcOffsetAt,
  }) {
    if (booking.status != BookingStatus.confirmed) return null;
    final d = booking.travelDate;
    // Normalised wall-clock components (day - 1 may cross a month/year).
    final wall = DateTime.utc(d.year, d.month, d.day - 1, reminderHour);
    final offset = (utcOffsetAt ?? _deviceOffsetAt)(wall);
    final at = wall.subtract(offset);
    // A minute of slack so a reminder isn't scheduled for "right now".
    return at.isAfter(now.add(const Duration(minutes: 1))) ? at : null;
  }

  /// The device's UTC offset at that local wall-clock time.
  static Duration _deviceOffsetAt(DateTime wall) =>
      DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute).timeZoneOffset;

  /// Stable, positive 31-bit id per booking, so re-scheduling replaces the
  /// existing reminder instead of adding a second one.
  static int notificationId(String bookingId) =>
      int.parse(stableDigest('trip-reminder:$bookingId').substring(0, 8), radix: 16) & 0x7fffffff;
}

/// What a trip reminder carries, so a tap can open the right booking and a
/// resync can tell whether the scheduled reminder is still current.
class TripReminderPayload {
  const TripReminderPayload({required this.bookingId, required this.at, required this.languageCode});

  static const kind = 'trip_reminder';

  final String bookingId;
  final DateTime at;
  final String languageCode;

  String encode() => jsonEncode({
        'kind': kind,
        'booking_id': bookingId,
        'at': at.toIso8601String(),
        'lang': languageCode,
      });

  /// `null` for anything that isn't a well-formed trip reminder payload.
  static TripReminderPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic> || json['kind'] != kind) return null;
      final bookingId = json['booking_id'];
      final at = DateTime.tryParse('${json['at']}');
      final lang = json['lang'];
      if (bookingId is! String || bookingId.isEmpty || at == null || lang is! String) return null;
      return TripReminderPayload(bookingId: bookingId, at: at, languageCode: lang);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TripReminderPayload &&
      other.bookingId == bookingId &&
      other.at == at &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(bookingId, at, languageCode);
}
