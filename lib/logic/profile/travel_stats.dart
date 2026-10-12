import 'package:equatable/equatable.dart';

import '../../data/models/booking.dart';

/// Traveller tiers, earned only from completed trips (see [TravelStats.level]).
enum TravelerLevel {
  newTraveler(0, 0),
  // A first completed trip always adds a country, so only trips count here.
  explorer(1, 0),
  voyager(3, 2),
  globetrotter(6, 3);

  const TravelerLevel(this.minTrips, this.minCountries);

  /// Completed trips needed.
  final int minTrips;

  /// Different countries visited needed.
  final int minCountries;

  TravelerLevel? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// Statistics derived **only** from the user's own bookings as stored in
/// Supabase. Nothing is estimated or invented:
///
/// * **completed** — confirmed bookings whose travel date has passed (the
///   database has no "completed" status; this is the same rule as the
///   "Past" tab in My trips)
/// * **upcoming** — confirmed, travel date today or later
/// * **cancelled** — status `cancelled`
/// * **destinations / countries visited** — distinct ones among completed
///   trips (country from the booking's embedded destination)
///
/// The [level] is a transparent tier based on completed trips and countries
/// — not a rating from other people (Rahala has no review system).
class TravelStats extends Equatable {
  const TravelStats({
    required this.totalBookings,
    required this.completedTrips,
    required this.upcomingTrips,
    required this.cancelledTrips,
    required this.destinationsVisited,
    required this.countriesVisited,
    required this.travelersBooked,
  });

  factory TravelStats.from(List<Booking> bookings, DateTime today) {
    final completed = bookings.where((b) => b.isPast(today)).toList();
    return TravelStats(
      totalBookings: bookings.length,
      completedTrips: completed.length,
      upcomingTrips: bookings.where((b) => b.isUpcoming(today)).length,
      cancelledTrips: bookings.where((b) => b.isCancelled).length,
      destinationsVisited: completed.map((b) => b.destinationId).toSet().length,
      countriesVisited: completed.map((b) => b.destination?.countryEn).whereType<String>().toSet().length,
      travelersBooked: bookings.where((b) => !b.isCancelled).fold(0, (sum, b) => sum + b.travelers),
    );
  }

  static const empty = TravelStats(
    totalBookings: 0,
    completedTrips: 0,
    upcomingTrips: 0,
    cancelledTrips: 0,
    destinationsVisited: 0,
    countriesVisited: 0,
    travelersBooked: 0,
  );

  final int totalBookings;
  final int completedTrips;
  final int upcomingTrips;
  final int cancelledTrips;
  final int destinationsVisited;
  final int countriesVisited;

  /// Seats booked on non-cancelled trips (you + companions).
  final int travelersBooked;

  /// Highest tier whose requirements are all met.
  TravelerLevel get level => TravelerLevel.values.lastWhere(
        (l) => completedTrips >= l.minTrips && countriesVisited >= l.minCountries,
      );

  /// 0…1 progress toward the next tier (1 at the top tier): the lower of the
  /// two requirement ratios, so the bar only fills when both are met.
  double get progressToNext {
    final next = level.next;
    if (next == null) return 1;
    final trips = next.minTrips == 0 ? 1.0 : (completedTrips / next.minTrips).clamp(0.0, 1.0);
    final countries = next.minCountries == 0 ? 1.0 : (countriesVisited / next.minCountries).clamp(0.0, 1.0);
    return trips < countries ? trips : countries;
  }

  /// What's still missing for the next tier.
  int get tripsToNext => level.next == null ? 0 : (level.next!.minTrips - completedTrips).clamp(0, 1 << 20);
  int get countriesToNext => level.next == null ? 0 : (level.next!.minCountries - countriesVisited).clamp(0, 1 << 20);

  @override
  List<Object?> get props => [
        totalBookings,
        completedTrips,
        upcomingTrips,
        cancelledTrips,
        destinationsVisited,
        countriesVisited,
        travelersBooked
      ];
}
