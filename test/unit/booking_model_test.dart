import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/data/models/booking.dart';

Map<String, dynamic> bookingRow({
  String status = 'confirmed',
  String travelDate = '2026-11-15',
  Object? destination = const {
    'id': 'd1',
    'name_en': 'Cairo',
    'name_ar': 'القاهرة',
    'country_en': 'Egypt',
    'country_ar': 'مصر',
    'cover_image': 'https://example.invalid/c.jpg',
  },
  Object? package = const {'id': 'p1', 'name_en': 'Weekend', 'name_ar': 'عطلة', 'duration_days': 2},
}) =>
    {
      'id': '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90',
      'reference': 'RH-3F9A1C2B',
      'user_id': 'u1',
      'destination_id': 'd1',
      'package_id': 'p1',
      'travel_date': travelDate,
      'travelers': 3,
      'unit_price': 180.00,
      'total_price': '540.00',
      'currency': 'USD',
      'status': status,
      'contact_name': 'Sara Ali',
      'contact_phone': '+20 100 000 0000',
      'special_requests': null,
      'created_at': '2026-10-02T09:30:00+00:00',
      'updated_at': '2026-10-02T09:30:00+00:00',
      'cancelled_at': status == 'cancelled' ? '2026-10-03T08:00:00+00:00' : null,
      'destination': destination,
      'package': package,
    };

void main() {
  group('Booking.fromJson', () {
    test('parses a bookings row with embedded catalog data', () {
      final b = Booking.fromJson(bookingRow());
      expect(b.reference, 'RH-3F9A1C2B');
      expect(b.travelDate, DateTime(2026, 11, 15));
      expect(b.travelers, 3);
      expect(b.unitPrice, 180);
      expect(b.totalPrice, 540, reason: 'numeric may arrive as a string');
      expect(b.status, BookingStatus.confirmed);
      expect(b.destination?.name('ar'), 'القاهرة');
      expect(b.package?.durationDays, 2);
      expect(b.createdAt.isUtc, isTrue);
    });

    test('embedded catalog data may be missing (hidden by RLS / RPC result)', () {
      final b = Booking.fromJson(bookingRow(destination: null, package: null));
      expect(b.destination, isNull);
      expect(b.package, isNull);
    });

    test('a cancelled row carries its cancellation time', () {
      final b = Booking.fromJson(bookingRow(status: 'cancelled'));
      expect(b.isCancelled, isTrue);
      expect(b.cancelledAt, isNotNull);
    });

    test('rejects statuses the database does not have, and malformed rows', () {
      expect(() => Booking.fromJson(bookingRow(status: 'paid')), throwsFormatException);
      expect(() => Booking.fromJson(bookingRow(travelDate: '15/11/2026')), throwsFormatException);
      expect(() => Booking.fromJson({...bookingRow()}..remove('reference')), throwsFormatException);
      expect(() => Booking.fromJson({...bookingRow(), 'travelers': 0}), throwsFormatException);
      expect(() => Booking.fromJson({...bookingRow(), 'destination': 'Cairo'}), throwsFormatException);
    });
  });

  group('date-based grouping (no "completed" status exists)', () {
    final today = DateTime(2026, 11, 15);
    Booking on(String date, [String status = 'confirmed']) =>
        Booking.fromJson(bookingRow(travelDate: date, status: status));

    test('upcoming / past / cancellable follow the server rules', () {
      final todayTrip = on('2026-11-15');
      expect(todayTrip.isUpcoming(today), isTrue);
      expect(todayTrip.canCancel(today), isFalse, reason: 'cancel_booking requires travel_date > current_date');

      final tomorrow = on('2026-11-16');
      expect(tomorrow.canCancel(today), isTrue);

      final yesterday = on('2026-11-14');
      expect(yesterday.isPast(today), isTrue);
      expect(yesterday.isUpcoming(today), isFalse);

      final cancelled = on('2026-12-01', 'cancelled');
      expect(cancelled.isUpcoming(today), isFalse);
      expect(cancelled.isPast(today), isFalse);
      expect(cancelled.canCancel(today), isFalse);
    });
  });

  group('BookingRequest.toInsertJson', () {
    test('sends only the columns the client may insert', () {
      final json = BookingRequest(
        destinationId: 'd1',
        packageId: 'p1',
        travelDate: DateTime(2026, 1, 5),
        travelers: 2,
        contactName: '  Sara Ali ',
        contactPhone: ' +20 100 ',
        specialRequests: '   ',
      ).toInsertJson();
      expect(
          json.keys,
          unorderedEquals([
            'destination_id',
            'package_id',
            'travel_date',
            'travelers',
            'contact_name',
            'contact_phone',
            'special_requests',
          ]));
      expect(json['travel_date'], '2026-01-05');
      expect(json['contact_name'], 'Sara Ali');
      expect(json['special_requests'], isNull, reason: 'blank notes are not stored');
    });
  });

  test('serverToday uses the UTC calendar date (Postgres current_date on Supabase)', () {
    // 01:30 in Cairo (UTC+3) on Oct 2 is still Oct 1 in UTC.
    final cairoLateNight = DateTime.parse('2026-10-02T01:30:00+03:00');
    expect(serverToday(cairoLateNight), DateTime(2026, 10));
  });
}
