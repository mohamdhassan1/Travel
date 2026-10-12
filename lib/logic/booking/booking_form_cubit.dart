import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/booking.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/booking_request_id_store.dart';
import '../../data/repositories/catalog_repository.dart';
import '../auth/auth_form_cubits.dart' show SubmitState, SubmitStatus;
import '../common/load_state.dart';

enum BookingStep { details, review }

class BookingFormState extends Equatable {
  const BookingFormState({
    this.destination = const LoadState.loading(),
    this.packages = const LoadState.loading(),
    this.packageId,
    this.travelDate,
    this.travelers = 1,
    this.step = BookingStep.details,
    this.contactName = '',
    this.contactPhone = '',
    this.specialRequests = '',
    this.submission = const SubmitState<Booking>(),
  });

  final LoadState<DestinationDetails> destination;
  final LoadState<List<TravelPackage>> packages;
  final String? packageId;
  final DateTime? travelDate;
  final int travelers;
  final BookingStep step;
  final String contactName;
  final String contactPhone;
  final String specialRequests;
  final SubmitState<Booking> submission;

  TravelPackage? get selectedPackage => packages.data?.where((p) => p.id == packageId).firstOrNull;

  /// `price × travellers` from the catalog, shown before submitting. The
  /// database computes the stored total itself.
  double? get estimatedTotal {
    final pkg = selectedPackage;
    return pkg == null ? null : pkg.pricePerPerson * travelers;
  }

  bool get isReady => destination.status == LoadStatus.success && packages.status == LoadStatus.success;
  bool get isSubmitting => submission.isSubmitting;
  bool get isBooked => submission.status == SubmitStatus.success;

  BookingFormState copyWith({
    LoadState<DestinationDetails>? destination,
    LoadState<List<TravelPackage>>? packages,
    String? packageId,
    DateTime? travelDate,
    int? travelers,
    BookingStep? step,
    String? contactName,
    String? contactPhone,
    String? specialRequests,
    SubmitState<Booking>? submission,
  }) =>
      BookingFormState(
        destination: destination ?? this.destination,
        packages: packages ?? this.packages,
        packageId: packageId ?? this.packageId,
        travelDate: travelDate ?? this.travelDate,
        travelers: travelers ?? this.travelers,
        step: step ?? this.step,
        contactName: contactName ?? this.contactName,
        contactPhone: contactPhone ?? this.contactPhone,
        specialRequests: specialRequests ?? this.specialRequests,
        submission: submission ?? this.submission,
      );

  @override
  List<Object?> get props => [
        destination,
        packages,
        packageId,
        travelDate,
        travelers,
        step,
        contactName,
        contactPhone,
        specialRequests,
        submission,
      ];
}

/// Drives the booking flow: choose package/date/travellers → review → submit.
class BookingFormCubit extends Cubit<BookingFormState> {
  BookingFormCubit({
    required CatalogRepository catalog,
    required BookingRepository bookings,
    required BookingRequestIdStore requestIds,
    required this.destinationId,
    String? initialPackageId,
    String initialContactName = '',
    String initialContactPhone = '',
    DateTime Function()? today,
  })  : _catalog = catalog,
        _bookings = bookings,
        _requestIds = requestIds,
        _today = today ?? serverToday,
        super(BookingFormState(
          packageId: initialPackageId,
          contactName: initialContactName,
          contactPhone: initialContactPhone,
        ));

  final CatalogRepository _catalog;
  final BookingRepository _bookings;
  final BookingRequestIdStore _requestIds;
  final DateTime Function() _today;
  final String destinationId;

  /// Bookable range enforced by the database: tomorrow … one year ahead
  /// (server date, UTC).
  DateTime get firstTravelDate => _today().add(const Duration(days: 1));
  DateTime get lastTravelDate => _today().add(const Duration(days: 365));

  Future<void> load() async {
    emit(state.copyWith(destination: const LoadState.loading(), packages: const LoadState.loading()));
    try {
      final results = await Future.wait<Object>([
        _catalog.fetchDestination(destinationId),
        _catalog.fetchPackages(destinationId),
      ]);
      final destination = results[0] as DestinationDetails;
      final packages = results[1] as List<TravelPackage>;
      if (isClosed) return;
      final selected = packages.any((p) => p.id == state.packageId)
          ? state.packageId
          : (packages.length == 1 ? packages.single.id : null);
      emit(state.copyWith(
        destination: LoadState.success(destination),
        packages: packages.isEmpty ? const LoadState.empty() : LoadState.success(packages),
        packageId: selected,
      ));
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(destination: LoadState.failure(failure)));
    }
  }

  void selectPackage(String packageId) {
    final pkg = state.packages.data?.where((p) => p.id == packageId).firstOrNull;
    if (pkg == null || state.isSubmitting) return;
    emit(state.copyWith(packageId: packageId, travelers: state.travelers.clamp(1, pkg.maxTravelers)));
  }

  void setTravelers(int travelers) {
    final max = state.selectedPackage?.maxTravelers ?? 1;
    if (state.isSubmitting) return;
    emit(state.copyWith(travelers: travelers.clamp(1, max)));
  }

  void setTravelDate(DateTime date) {
    if (state.isSubmitting) return;
    emit(state.copyWith(travelDate: DateTime(date.year, date.month, date.day)));
  }

  /// Moves to the review step. Returns `false` (staying on details) if the
  /// package or date is missing/out of range; text fields are validated by
  /// the form before this is called.
  bool review({required String contactName, required String contactPhone, required String specialRequests}) {
    final date = state.travelDate;
    final valid = state.selectedPackage != null &&
        date != null &&
        !date.isBefore(firstTravelDate) &&
        !date.isAfter(lastTravelDate);
    if (!valid) return false;
    emit(state.copyWith(
      contactName: contactName.trim(),
      contactPhone: contactPhone.trim(),
      specialRequests: specialRequests.trim(),
      step: BookingStep.review,
      submission: const SubmitState<Booking>(),
    ));
    return true;
  }

  void backToDetails() {
    if (state.isSubmitting || state.isBooked) return;
    emit(state.copyWith(step: BookingStep.details));
  }

  /// Submits once. Ignored while a request is in flight and after success,
  /// so double taps can't create duplicate bookings.
  ///
  /// Every attempt carries an idempotency key. If the outcome is unknown
  /// (network loss, timeout, unreadable response) the key is kept, so the
  /// retry — now or after an app restart — returns the booking the server
  /// may already have created instead of creating another one.
  Future<void> submit() async {
    final pkg = state.selectedPackage;
    final date = state.travelDate;
    if (state.isSubmitting || state.isBooked || state.step != BookingStep.review || pkg == null || date == null) {
      return;
    }
    emit(state.copyWith(submission: const SubmitState<Booking>(status: SubmitStatus.submitting)));
    final request = BookingRequest(
      destinationId: destinationId,
      packageId: pkg.id,
      travelDate: date,
      travelers: state.travelers,
      contactName: state.contactName,
      contactPhone: state.contactPhone,
      specialRequests: state.specialRequests.isEmpty ? null : state.specialRequests,
    );
    final fingerprint = request.fingerprint;
    try {
      final requestId = await _requestIds.idFor(fingerprint);
      final booking = await _bookings.createBooking(request.withClientRequestId(requestId));
      await _requestIds.release(fingerprint);
      if (!isClosed) {
        emit(state.copyWith(submission: SubmitState<Booking>(status: SubmitStatus.success, result: booking)));
      }
    } on AppFailure catch (failure) {
      // A definite rejection means nothing was booked: the next attempt
      // (e.g. after fixing the date) is a new request.
      if (isDefiniteRejection(failure)) await _requestIds.release(fingerprint);
      if (!isClosed) {
        emit(state.copyWith(submission: SubmitState<Booking>(status: SubmitStatus.failure, failure: failure)));
      }
    } catch (error, stack) {
      AppLogger.error('Unexpected booking error', error: error, stackTrace: stack);
      if (!isClosed) {
        emit(state.copyWith(
          submission: SubmitState<Booking>(
            status: SubmitStatus.failure,
            failure: AppFailure(FailureType.unknown, debugMessage: error.toString()),
          ),
        ));
      }
    }
  }
}

/// Failures where the server certainly did not create the booking. Anything
/// else (network, timeout, server error, unreadable response, unknown) may
/// have happened after the row was stored, so the request id is kept.
bool isDefiniteRejection(AppFailure failure) => switch (failure.type) {
      FailureType.packageUnavailable ||
      FailureType.tooManyTravelers ||
      FailureType.invalidTravelDate ||
      FailureType.bookingRateLimited ||
      FailureType.invalidInput ||
      FailureType.permissionDenied ||
      FailureType.sessionExpired ||
      FailureType.idempotencyConflict =>
        true,
      _ => false,
    };
