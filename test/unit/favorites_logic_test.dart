import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/catalog/destination_details_cubit.dart';
import 'package:rahala/logic/common/load_state.dart';
import 'package:rahala/logic/favorites/favorite_destinations_cubit.dart';
import 'package:rahala/logic/favorites/favorites_cubit.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_data_repositories.dart';

void main() {
  group('DestinationDetailsCubit', () {
    test('loads destination and packages', () async {
      final cubit = DestinationDetailsCubit(FakeCatalogRepository(), 'id-cairo');
      await cubit.load();
      expect(cubit.state.destination.status, LoadStatus.success);
      expect(cubit.state.destination.data!.nameEn, 'Cairo');
      expect(cubit.state.packages.data, hasLength(2));
    });

    test('an unknown id ends in notFound', () async {
      final cubit = DestinationDetailsCubit(FakeCatalogRepository(), 'does-not-exist');
      await cubit.load();
      expect(cubit.state.destination.failure?.type, FailureType.notFound);
    });

    test('a destination without packages has an empty packages state', () async {
      final cubit = DestinationDetailsCubit(FakeCatalogRepository(), 'id-kyoto');
      await cubit.load();
      expect(cubit.state.destination.status, LoadStatus.success);
      expect(cubit.state.packages.status, LoadStatus.empty);
    });

    test('a packages failure keeps the destination and can be retried alone', () async {
      final catalog = FakeCatalogRepository()..nextPackagesFailure = const AppFailure(FailureType.network);
      final cubit = DestinationDetailsCubit(catalog, 'id-cairo');
      await cubit.load();
      expect(cubit.state.destination.status, LoadStatus.success);
      expect(cubit.state.packages.failure?.type, FailureType.network);

      await cubit.loadPackages();
      expect(cubit.state.packages.status, LoadStatus.success);
    });
  });

  group('FavoritesCubit', () {
    late FakeAuthRepository auth;
    late SessionCubit session;
    late String? currentUser;
    late FakeFavoritesRepository repo;

    setUp(() {
      auth = FakeAuthRepository(signedInAs: testUser);
      session = SessionCubit(auth);
      currentUser = testUser.id;
      repo = FakeFavoritesRepository(currentUserId: () => currentUser, initial: {
        testUser.id: ['id-kyoto'],
        'user-2': ['id-cairo'],
      });
    });

    tearDown(() async {
      await session.close();
      await auth.dispose();
    });

    Future<FavoritesCubit> ready() async {
      final cubit = FavoritesCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.status, FavoritesStatus.ready);
      return cubit;
    }

    test('loads the signed-in user\'s favourites', () async {
      final cubit = await ready();
      expect(cubit.state.ids, ['id-kyoto']);
      expect(cubit.state.isFavorite('id-cairo'), isFalse);
    });

    test('stays empty while signed out', () async {
      await auth.signOut();
      await pumpEventQueue();
      final cubit = FavoritesCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.status, FavoritesStatus.signedOut);
      expect(repo.calls, isEmpty);
    });

    test('add: optimistic, then confirmed by the server', () async {
      final cubit = await ready();
      repo.writeGate = Completer<void>();
      final done = cubit.toggle('id-cairo');

      expect(cubit.state.isFavorite('id-cairo'), isTrue, reason: 'optimistic');
      expect(cubit.state.isPending('id-cairo'), isTrue);

      repo.writeGate!.complete();
      await done;
      expect(cubit.state.isPending('id-cairo'), isFalse);
      expect(cubit.state.lastEvent?.change, FavoriteChange.added);
      expect(repo.idsFor(testUser.id), contains('id-cairo'));
    });

    test('a failed add is rolled back and reported', () async {
      final cubit = await ready();
      repo.nextWriteFailure = const AppFailure(FailureType.network);
      await cubit.toggle('id-cairo');

      expect(cubit.state.isFavorite('id-cairo'), isFalse);
      expect(cubit.state.lastEvent?.change, FavoriteChange.addFailed);
      expect(cubit.state.lastEvent?.failure?.type, FailureType.network);
      expect(repo.idsFor(testUser.id), isNot(contains('id-cairo')));
    });

    test('remove succeeds; a failed remove is rolled back', () async {
      final cubit = await ready();
      await cubit.toggle('id-kyoto');
      expect(cubit.state.ids, isEmpty);
      expect(cubit.state.lastEvent?.change, FavoriteChange.removed);

      await cubit.toggle('id-kyoto'); // re-add
      repo.nextWriteFailure = const AppFailure(FailureType.permissionDenied);
      await cubit.toggle('id-kyoto');
      expect(cubit.state.isFavorite('id-kyoto'), isTrue);
      expect(cubit.state.lastEvent?.change, FavoriteChange.removeFailed);
    });

    test('double taps while a request is in flight send one request', () async {
      final cubit = await ready();
      repo.writeGate = Completer<void>();
      final first = cubit.toggle('id-cairo');
      final second = cubit.toggle('id-cairo');
      repo.writeGate!.complete();
      await Future.wait([first, second]);
      expect(repo.calls.where((c) => c == 'add:id-cairo'), hasLength(1));
      expect(cubit.state.isFavorite('id-cairo'), isTrue);
    });

    test('a load failure is reported and can be retried', () async {
      repo.nextLoadFailure = const AppFailure(FailureType.server);
      final cubit = FavoritesCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.status, FavoritesStatus.failure);
      await cubit.load();
      expect(cubit.state.status, FavoritesStatus.ready);
    });

    test('signing out clears favourites; signing back in restores them from the server', () async {
      final cubit = await ready();
      await cubit.toggle('id-cairo');
      expect(cubit.state.ids, ['id-cairo', 'id-kyoto']);

      await auth.signOut();
      await pumpEventQueue();
      expect(cubit.state.status, FavoritesStatus.signedOut);
      expect(cubit.state.ids, isEmpty, reason: 'nothing kept in memory after sign-out');

      await auth.signIn(email: testUser.email, password: 'x');
      await pumpEventQueue();
      expect(cubit.state.status, FavoritesStatus.ready);
      expect(cubit.state.ids, ['id-cairo', 'id-kyoto'], reason: 'persisted server-side');
    });

    test('switching accounts never shows the previous user\'s favourites', () async {
      final cubit = await ready();
      expect(cubit.state.ids, ['id-kyoto']);

      final seen = <List<String>>[];
      final sub = cubit.stream.listen((s) => seen.add(s.ids));
      currentUser = 'user-2';
      auth.switchTo(const AppUser(id: 'user-2', email: 'b@example.com'));
      await pumpEventQueue();
      await sub.cancel();

      expect(cubit.state.ids, ['id-cairo']);
      // Every intermediate state after the switch is either empty or user-2's.
      expect(seen.where((ids) => ids.contains('id-kyoto')), isEmpty);
    });
  });

  group('FavoriteDestinationsCubit', () {
    test('shows saved destinations, follows removals, and is empty at the end', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final repo = FakeFavoritesRepository(initial: {
        testUser.id: ['id-kyoto', 'id-cairo'],
      });
      final favorites = FavoritesCubit(repo, session);
      final catalog = FakeCatalogRepository();
      final cubit = FavoriteDestinationsCubit(catalog, favorites);
      await pumpEventQueue();

      expect(cubit.state.data!.map((d) => d.id), ['id-kyoto', 'id-cairo']);

      await favorites.toggle('id-kyoto');
      await pumpEventQueue();
      expect(cubit.state.data!.map((d) => d.id), ['id-cairo']);

      await favorites.toggle('id-cairo');
      await pumpEventQueue();
      expect(cubit.state.status, LoadStatus.empty);
      expect(catalog.byIdCalls, hasLength(1), reason: 'removals need no refetch');

      await session.close();
      await auth.dispose();
    });

    test('a favourites load failure surfaces as an error with retry', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final repo = FakeFavoritesRepository()..nextLoadFailure = const AppFailure(FailureType.network);
      final favorites = FavoritesCubit(repo, session);
      final cubit = FavoriteDestinationsCubit(FakeCatalogRepository(), favorites);
      await pumpEventQueue();
      expect(cubit.state.failure?.type, FailureType.network);

      await cubit.retry();
      await pumpEventQueue();
      expect(cubit.state.status, LoadStatus.empty);

      await session.close();
      await auth.dispose();
    });
  });
}
