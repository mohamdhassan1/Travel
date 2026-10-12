import 'package:equatable/equatable.dart';

enum FailureType {
  network,
  timeout,
  invalidCredentials,
  emailNotConfirmed,
  emailAlreadyRegistered,
  weakPassword,
  samePassword,
  signupDisabled,
  rateLimited,
  sessionExpired,
  permissionDenied,
  notFound,
  server,

  /// The server answered, but the payload could not be understood.
  invalidData,

  /// The server rejected input that failed a database constraint.
  invalidInput,

  // Booking rules enforced by the database (see `prepare_booking` /
  // `cancel_booking` in the Supabase migration).
  packageUnavailable,
  tooManyTravelers,
  invalidTravelDate,
  bookingNotCancellable,

  /// Too many bookings in a short time (server abuse cap, not availability).
  bookingRateLimited,

  /// A retried booking request id already belongs to a different booking.
  idempotencyConflict,
  unknown,
}

/// A failure that is safe to show to users (via its localized [type]) while
/// keeping a [debugMessage] for developer diagnostics.
///
/// Data-layer code converts SDK/transport exceptions into [AppFailure] so the
/// UI never has to know about Supabase, Dio, or sockets.
class AppFailure extends Equatable implements Exception {
  const AppFailure(this.type, {this.debugMessage});

  final FailureType type;
  final String? debugMessage;

  /// Whether retrying the same operation could reasonably succeed.
  bool get isTransient => switch (type) {
        FailureType.network || FailureType.timeout || FailureType.server || FailureType.rateLimited => true,
        _ => false,
      };

  @override
  List<Object?> get props => [type];

  @override
  String toString() => 'AppFailure(${type.name}${debugMessage == null ? '' : ': $debugMessage'})';
}
