import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/core/utils/validators.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/repositories/booking_request_id_store.dart';
import 'package:rahala/logic/auth/auth_form_cubits.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/booking/booking_details_cubit.dart';
import 'package:rahala/logic/booking/booking_form_cubit.dart';
import 'package:rahala/logic/booking/my_bookings_cubit.dart';
import 'package:rahala/logic/common/load_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_data_repositories.dart';

void main() {
  final today = DateTime(2026, 10);

  group('BookingValidators (mirror the database CHECK constraints)', () {
    test('phone', () {
      expect(BookingValidators.contactPhone(''), FieldError.required);
      expect(BookingValidators.contactPhone('12345'), FieldError.invalidPhone);
      expect(BookingValidators.contactPhone('abc-defg'), FieldError.invalidPhone);
      expect(BookingValidators.contactPhone('------'), FieldError.invalidPhone);
      expect(BookingValidators.contactPhone('+20 (100) 000-0000'), isNull);
    });

    test('special requests length', () {
      expect(BookingValidators.specialRequests('a' * 500), isNull);
      expect(BookingValidators.specialRequests('a' * 501), FieldError.textTooLong);
    });
  });

  group('BookingFormCubit', () {
    late BookingRequestIdStore requestIds;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      requestIds = BookingRequestIdStore(await SharedPreferences.getInstance());
    });

    BookingFormCubit build(FakeBookingRepository bookings, {String? packageId = 'pkg-1'}) => BookingFormCubit(
          catalog: FakeCatalogRepository(),
          bookings: bookings,
          requestIds: requestIds,
          destinationId: 'id-cairo',
          initialPackageId: packageId,
          today: () => today,
        );

    Future<BookingFormCubit> reviewed(FakeBookingRepository bookings) async {
      final cubit = build(bookings);
      await cubit.load();
      cubit.setTravelDate(today.add(const Duration(days: 10)));
      cubit.setTravelers(2);
      expect(cubit.review(contactName: 'Sara Ali', contactPhone: '+20 100 000 0000', specialRequests: ''), isTrue);
      return cubit;
    }

    test('loads destination and packages; keeps the preselected package', () async {
      final cubit = build(FakeBookingRepository(today: today));
      await cubit.load();
      expect(cubit.state.isReady, isTrue);
      expect(cubit.state.selectedPackage?.id, 'pkg-1');
    });

    test('an unknown destination fails with notFound', () async {
      final cubit = BookingFormCubit(
        catalog: FakeCatalogRepository(),
        bookings: FakeBookingRepository(today: today),
        requestIds: requestIds,
        destinationId: 'nope',
        today: () => today,
      );
      await cubit.load();
      expect(cubit.state.destination.failure?.type, FailureType.notFound);
    });

    test('travellers are clamped to the package maximum', () async {
      final cubit = build(FakeBookingRepository(today: today));
      await cubit.load();
      cubit.setTravelers(50);
      expect(cubit.state.travelers, 8);
      cubit.selectPackage('pkg-2'); // Cairo Weekend Escape also allows 8 in the fake
      cubit.setTravelers(0);
      expect(cubit.state.travelers, 1);
    });

    test('review requires a package and a date inside the bookable range', () async {
      final cubit = build(FakeBookingRepository(today: today), packageId: null);
      await cubit.load();
      expect(cubit.review(contactName: 'Sara', contactPhone: '+20 100 000', specialRequests: ''), isFalse);

      cubit.selectPackage('pkg-1');
      cubit.setTravelDate(today); // today is not bookable
      expect(cubit.review(contactName: 'Sara', contactPhone: '+20 100 000', specialRequests: ''), isFalse);

      cubit.setTravelDate(today.add(const Duration(days: 366)));
      expect(cubit.review(contactName: 'Sara', contactPhone: '+20 100 000', specialRequests: ''), isFalse);

      cubit.setTravelDate(today.add(const Duration(days: 1)));
      expect(cubit.review(contactName: 'Sara', contactPhone: '+20 100 000', specialRequests: ''), isTrue);
      expect(cubit.state.step, BookingStep.review);
    });

    test('submit succeeds only with the stored booking from the backend', () async {
      final repo = FakeBookingRepository(today: today);
      final cubit = await reviewed(repo);
      await cubit.submit();

      expect(cubit.state.submission.status, SubmitStatus.success);
      final booking = cubit.state.submission.result!;
      expect(booking.totalPrice, 840, reason: 'computed by the backend: 420 × 2');
      expect(repo.countFor('user-1'), 1);
    });

    test('a backend failure is reported and nothing is marked as booked', () async {
      final repo = FakeBookingRepository(today: today)..nextCreateFailure = const AppFailure(FailureType.network);
      final cubit = await reviewed(repo);
      await cubit.submit();

      expect(cubit.state.submission.status, SubmitStatus.failure);
      expect(cubit.state.submission.failure?.type, FailureType.network);
      expect(cubit.state.isBooked, isFalse);
      expect(repo.countFor('user-1'), 0);

      // Retry after a recoverable error works.
      await cubit.submit();
      expect(cubit.state.isBooked, isTrue);
    });

    test('double submit sends one request; nothing more after success', () async {
      final repo = FakeBookingRepository(today: today)..createGate = Completer<void>();
      final cubit = await reviewed(repo);
      final first = cubit.submit();
      final second = cubit.submit();
      repo.createGate!.complete();
      await Future.wait([first, second]);
      await cubit.submit(); // after success

      expect(repo.calls.where((c) => c == 'create'), hasLength(1));
      expect(repo.countFor('user-1'), 1);
    });

    test('selection cannot change while submitting', () async {
      final repo = FakeBookingRepository(today: today)..createGate = Completer<void>();
      final cubit = await reviewed(repo);
      final pending = cubit.submit();
      cubit.setTravelers(5);
      cubit.backToDetails();
      expect(cubit.state.travelers, 2);
      expect(cubit.state.step, BookingStep.review);
      repo.createGate!.complete();
      await pending;
    });
  });

  group('MyBookingsCubit', () {
    late FakeAuthRepository auth;
    late SessionCubit session;
    late String? currentUser;
    late FakeBookingRepository repo;

    setUp(() {
      auth = FakeAuthRepository(signedInAs: testUser);
      session = SessionCubit(auth);
      currentUser = testUser.id;
      repo = FakeBookingRepository(currentUserId: () => currentUser, today: today);
    });

    tearDown(() async {
      await session.close();
      await auth.dispose();
    });

    test('loads the user\'s bookings; empty when there are none', () async {
      final cubit = MyBookingsCubit(repo, session);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);

      repo.seed(userId: testUser.id);
      await cubit.load();
      expect(cubit.state.data, hasLength(1));
    });

    test('error then retry', () async {
      repo.nextLoadFailure = const AppFailure(FailureType.server);
      final cubit = MyBookingsCubit(repo, session);
      await cubit.load();
      expect(cubit.state.failure?.type, FailureType.server);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);
    });

    test('never shows another account\'s bookings, including after switching users', () async {
      repo.seed(userId: testUser.id);
      repo.seed(userId: 'user-2');
      repo.seed(userId: 'user-2');
      final cubit = MyBookingsCubit(repo, session);
      await cubit.load();
      expect(cubit.state.data, hasLength(1));

      final seen = <LoadState<List<Booking>>>[];
      final sub = cubit.stream.listen(seen.add);
      currentUser = 'user-2';
      auth.switchTo(const AppUser(id: 'user-2', email: 'b@example.com'));
      await pumpEventQueue();
      await sub.cancel();

      expect(cubit.state.data, hasLength(2));
      expect(seen.first.status, LoadStatus.loading, reason: 'previous user\'s list dropped first');
    });

    test('sign-out clears the list', () async {
      repo.seed(userId: testUser.id);
      final cubit = MyBookingsCubit(repo, session);
      await cubit.load();
      await auth.signOut();
      await pumpEventQueue();
      expect(cubit.state.data, isNull);
    });
  });

  group('BookingDetailsCubit', () {
    late FakeAuthRepository auth;
    late SessionCubit session;
    late FakeBookingRepository repo;

    setUp(() {
      auth = FakeAuthRepository(signedInAs: testUser);
      session = SessionCubit(auth);
      repo = FakeBookingRepository(today: today);
    });

    tearDown(() async {
      await session.close();
      await auth.dispose();
    });

    test('another user\'s booking is not found', () async {
      final theirs = repo.seed(userId: 'user-2');
      final cubit = BookingDetailsCubit(repo, session, theirs.id);
      await cubit.load();
      expect(cubit.state.booking.failure?.type, FailureType.notFound);
    });

    test('cancel: shown as cancelled only after the backend confirms; embeds kept', () async {
      final mine = repo.seed(userId: testUser.id);
      final cubit = BookingDetailsCubit(repo, session, mine.id);
      await cubit.load();
      await cubit.cancel();

      expect(cubit.state.cancellation.status, SubmitStatus.success);
      expect(cubit.state.booking.data!.isCancelled, isTrue);
      expect(cubit.state.booking.data!.destination, isNotNull, reason: 'kept from before');
      expect(repo.storedBooking(mine.id).isCancelled, isTrue);
    });

    test('a failed cancel leaves the booking as the backend has it', () async {
      final mine = repo.seed(userId: testUser.id);
      repo.nextCancelFailure = const AppFailure(FailureType.network);
      final cubit = BookingDetailsCubit(repo, session, mine.id);
      await cubit.load();
      await cubit.cancel();

      expect(cubit.state.cancellation.status, SubmitStatus.failure);
      expect(cubit.state.booking.data!.isCancelled, isFalse);
      expect(repo.storedBooking(mine.id).isCancelled, isFalse);
    });

    test('the backend refuses to cancel a booking that is not cancellable', () async {
      final soon = repo.seed(userId: testUser.id, travelDate: today); // travel_date = today
      final cubit = BookingDetailsCubit(repo, session, soon.id);
      await cubit.load();
      await cubit.cancel();
      expect(cubit.state.cancellation.failure?.type, FailureType.bookingNotCancellable);
      expect(cubit.state.booking.data!.isCancelled, isFalse);
    });
  });
}
