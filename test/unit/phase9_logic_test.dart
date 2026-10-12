import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/account_repository.dart';
import 'package:rahala/data/repositories/booking_repository.dart';
import 'package:rahala/data/repositories/booking_request_id_store.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/booking/booking_form_cubit.dart';
import 'package:rahala/logic/booking/my_bookings_cubit.dart';
import 'package:rahala/logic/common/load_state.dart';
import 'package:rahala/logic/favorites/favorites_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_data_repositories.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('MyBookingsCubit and account changes', () {
    test('a slow response for the previous account is dropped after sign-out', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final repo = FakeBookingRepository(currentUserId: () => auth.currentUser?.id)..seed(userId: testUser.id);
      final cubit = MyBookingsCubit(repo, session);
      addTearDown(cubit.close);
      addTearDown(session.close);

      repo.loadGate = Completer<void>();
      final pending = cubit.load();
      await settle();
      await auth.signOut();
      await settle();
      repo.loadGate!.complete();
      await pending;

      expect(session.state.isAuthenticated, isFalse);
      expect(cubit.state.status, LoadStatus.loading, reason: 'nothing loaded for a signed-out user');
      expect(cubit.state.data, isNull, reason: 'the previous account\'s trips never reappear');
    });
  });

  group('Account deletion', () {
    test('deletes on the server first, then signs out as a user action', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      addTearDown(session.close);
      final account = FakeAccountRepository();

      await session.deleteAccount(account.deleteMyAccount);
      await settle();

      expect(account.deleted, 1);
      expect(auth.calls, ['signOut']);
      expect(session.state.status, SessionStatus.unauthenticated);
      expect(session.state.endedUnexpectedly, isFalse, reason: 'no "you were signed out" notice');
    });

    test('a refused deletion leaves the user signed in and reports the failure', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      addTearDown(session.close);
      final account = FakeAccountRepository(failure: const AppFailure(FailureType.network));

      await expectLater(
        session.deleteAccount(account.deleteMyAccount),
        throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.network)),
      );
      expect(auth.calls, isEmpty, reason: 'not signed out when nothing was deleted');
      expect(session.state.isAuthenticated, isTrue);
    });

    test('a photo that could not be removed maps to a retryable server failure', () {
      final failure = mapAccountError(const PostgrestException(message: 'avatar_cleanup_required', code: 'P0001'));
      expect(failure.type, FailureType.server);
      expect(failure.isTransient, isTrue);
    });

    test('migration: owner-only, refuses while files remain, no anon access', () {
      final sql = File('supabase/migrations/20261004000000_account_deletion_and_hardening.sql').readAsStringSync();
      expect(sql, contains('create or replace function public.delete_my_account()'));
      expect(sql, contains('security definer'));
      expect(sql, contains("raise exception 'avatar_cleanup_required'"));
      expect(sql, contains('delete from auth.users where id = v_uid;'));
      expect(sql, contains('revoke all on function public.delete_my_account() from public, anon;'));
      expect(sql, contains('grant execute on function public.delete_my_account() to authenticated;'));
    });
  });

  group('Booking abuse cap', () {
    test('the server\'s rate limit maps to its own, definite failure', () {
      final failure = mapBookingError(const PostgrestException(message: 'booking_rate_limited', code: 'P0001'));
      expect(failure.type, FailureType.bookingRateLimited);
      expect(isDefiniteRejection(failure), isTrue, reason: 'nothing was booked, so the request id is released');
    });

    test('migration: idempotent retries are exempt from the cap', () {
      final sql = File('supabase/migrations/20261004000000_account_deletion_and_hardening.sql').readAsStringSync();
      expect(sql, contains("raise exception 'booking_rate_limited'"));
      expect(sql, contains('b.client_request_id = new.client_request_id'));
      expect(sql, contains("interval '1 hour'"));
    });
  });

  group('FavoritesCubit.refresh', () {
    test('picks up a destination saved on another device, keeping the list on screen', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final repo = FakeFavoritesRepository(currentUserId: () => auth.currentUser?.id, initial: {
        testUser.id: ['id-cairo'],
      });
      final cubit = FavoritesCubit(repo, session);
      addTearDown(cubit.close);
      addTearDown(session.close);
      await settle();
      expect(cubit.state.ids, ['id-cairo']);

      await repo.addFavorite('id-kyoto'); // elsewhere
      final states = <FavoritesStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));
      await cubit.refresh();
      await sub.cancel();

      expect(cubit.state.ids, ['id-kyoto', 'id-cairo']);
      expect(states, isNot(contains(FavoritesStatus.loading)), reason: 'no skeleton flash on refresh');
    });

    test('a failed refresh keeps the saved list and reports the failure', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final repo = FakeFavoritesRepository(currentUserId: () => auth.currentUser?.id, initial: {
        testUser.id: ['id-cairo'],
      });
      final cubit = FavoritesCubit(repo, session);
      addTearDown(cubit.close);
      addTearDown(session.close);
      await settle();

      repo.nextLoadFailure = const AppFailure(FailureType.network);
      await cubit.refresh();
      expect(cubit.state.status, FavoritesStatus.ready);
      expect(cubit.state.ids, ['id-cairo']);
      expect(cubit.state.failure?.type, FailureType.network);
    });
  });

  group('Booking form prefill', () {
    test('contact phone starts from the profile (still editable)', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = BookingFormCubit(
        catalog: FakeCatalogRepository(),
        bookings: FakeBookingRepository(),
        requestIds: BookingRequestIdStore(await SharedPreferences.getInstance()),
        destinationId: 'id-cairo',
        initialContactName: 'Sara Ali',
        initialContactPhone: '+20 100 000 0000',
      );
      addTearDown(cubit.close);
      expect(cubit.state.contactName, 'Sara Ali');
      expect(cubit.state.contactPhone, '+20 100 000 0000');
    });
  });
}
