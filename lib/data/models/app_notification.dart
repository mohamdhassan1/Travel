import 'package:equatable/equatable.dart';

import 'booking.dart' show parseDateOnly;
import 'json_read.dart';

/// Values of the `public.notification_type` enum.
enum NotificationType { bookingConfirmed, bookingCancelled, tripReminder }

const _typeNames = {
  'booking_confirmed': NotificationType.bookingConfirmed,
  'booking_cancelled': NotificationType.bookingCancelled,
  'trip_reminder': NotificationType.tripReminder,
};

/// A row of `public.notifications`, written by the database (the
/// `notify_booking_change` trigger) — the app never creates them.
///
/// `data` is a JSON snapshot taken when the notification was created
/// (reference, travel date, destination names); each field is optional so an
/// older or partial payload still displays.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.bookingId,
    this.reference,
    this.travelDate,
    this.destinationNameEn,
    this.destinationNameAr,
    this.readAt,
  });

  /// Throws [FormatException] for a row without id/type/created_at or with an
  /// unknown type; optional `data` fields that are malformed are ignored.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final typeName = json.str('type');
    final type = _typeNames[typeName] ?? (throw FormatException('Unknown notification type', typeName));
    final data =
        json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : const <String, dynamic>{};

    String? text(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    DateTime? date(String key) {
      final value = text(key);
      if (value == null) return null;
      try {
        return parseDateOnly(value);
      } on FormatException {
        return null;
      }
    }

    return AppNotification(
      id: json.str('id'),
      type: type,
      bookingId: json.strOrNull('booking_id'),
      reference: text('reference'),
      travelDate: date('travel_date'),
      destinationNameEn: text('destination_name_en'),
      destinationNameAr: text('destination_name_ar'),
      readAt: json.dateOrNull('read_at'),
      createdAt: json.dateOrNull('created_at') ?? (throw const FormatException('Missing created_at')),
    );
  }

  final String id;
  final NotificationType type;

  /// `null` when the notification isn't about a booking (or it was deleted).
  final String? bookingId;
  final String? reference;
  final DateTime? travelDate;
  final String? destinationNameEn;
  final String? destinationNameAr;

  /// Set by the server (`mark_notifications_read`); `null` means unread.
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  /// The destination name in [languageCode], falling back to the other
  /// language if only one was stored.
  String? destinationName(String languageCode) {
    final en = destinationNameEn ?? destinationNameAr;
    final ar = destinationNameAr ?? destinationNameEn;
    if (en == null || ar == null) return null;
    return pickLocalized(languageCode, en: en, ar: ar);
  }

  /// This notification with the server's read state.
  AppNotification withReadAt(DateTime? value) => AppNotification(
        id: id,
        type: type,
        createdAt: createdAt,
        bookingId: bookingId,
        reference: reference,
        travelDate: travelDate,
        destinationNameEn: destinationNameEn,
        destinationNameAr: destinationNameAr,
        readAt: value,
      );

  @override
  List<Object?> get props => [id, type, bookingId, reference, travelDate, readAt, createdAt];
}
