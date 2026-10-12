import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/catalog/catalog_cubit.dart';
import 'package:rahala/logic/common/load_state.dart';
import 'package:rahala/logic/profile/profile_cubit.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_data_repositories.dart';

void main() {
  // The app-wide catalog (the old per-screen DestinationsCubit was removed;
  // its remaining behaviours are covered here and in phase8_logic_test).
  group('CatalogCubit', () {
    blocTest<CatalogCubit, CatalogState>(
      'an empty catalog is ready with no destinations, not an error',
      build: () => CatalogCubit(FakeCatalogRepository(destinations: [])),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.isReady, isTrue);
        expect(c.state.destinations, isEmpty);
        expect(c.state.failure, isNull);
      },
    );

    test('concurrent loads hit the backend once', () async {
      final repo = FakeCatalogRepository()..gate = Completer<void>();
      final cubit = CatalogCubit(repo);
      final a = cubit.load();
      final b = cubit.load();
      repo.gate!.complete();
      await Future.wait([a, b]);
      expect(repo.destinationCalls, 1);
      expect(cubit.state.destinations, sampleDestinations);
      await cubit.close();
    });

    test('a refresh keeps showing current data instead of a spinner', () async {
      final repo = FakeCatalogRepository();
      final cubit = CatalogCubit(repo);
      await cubit.load();
      final states = <CatalogStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));
      await cubit.load();
      await pumpEventQueue();
      expect(states, isNot(contains(CatalogStatus.loading)));
      expect(cubit.state.destinations, isNotEmpty);
      await sub.cancel();
      await cubit.close();
    });
  });

  group('ProfileCubit', () {
    test('loads the profile row for the signed-in user', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final cubit = ProfileCubit(FakeProfileRepository(), session);
      expect(cubit.state.status, LoadStatus.loading);
      await pumpEventQueue();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.profile, const UserProfile(id: 'user-1', fullName: 'Sara Ali'));
      await cubit.close();
      await session.close();
      await auth.dispose();
    });

    test('reports a missing row as notFound', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final cubit =
          ProfileCubit(FakeProfileRepository()..nextFailure = const AppFailure(FailureType.notFound), session);
      await pumpEventQueue();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.failure?.type, FailureType.notFound);
      await cubit.close();
      await session.close();
      await auth.dispose();
    });
  });
}
