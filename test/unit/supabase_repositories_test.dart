import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/repositories/catalog_repository.dart';
import 'package:rahala/data/repositories/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_data_repositories.dart';

/// Exercises the real Supabase repositories against a fake HTTP server, so
/// the exact PostgREST requests are verified without a live project.
void main() {
  const cairoId = '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90';
  const userId = '7d1e2c3b-4a5f-4e6d-8c7b-9a0f1e2d3c4b';

  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late SupabaseClient client;

  http.Response json(Object body, {int status = 200}) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  setUp(() {
    requests = [];
    respond = (_) => json([]);
    client = SupabaseClient(
      'https://test-project.supabase.co',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final r = respond(request);
        // Real responses carry their request; postgrest relies on it.
        return http.Response.bytes(r.bodyBytes, r.statusCode, headers: r.headers, request: request);
      }),
    );
  });

  tearDown(() => client.dispose());

  Matcher failure(FailureType type) => throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

  group('SupabaseCatalogRepository', () {
    late SupabaseCatalogRepository repo;
    setUp(() => repo = SupabaseCatalogRepository(client));

    test('fetchDestination queries by id and parses the row', () async {
      respond = (_) => json([
            {...destinationDetailsRow(), 'id': cairoId},
          ]);
      final d = await repo.fetchDestination(cairoId);

      expect(d.id, cairoId);
      expect(d.nameEn, 'Cairo');
      final uri = requests.single.url;
      expect(uri.path, '/rest/v1/destinations');
      expect(uri.queryParameters['id'], 'eq.$cairoId');
    });

    test('an unknown id is notFound', () async {
      respond = (_) => json([]);
      await expectLater(repo.fetchDestination(cairoId), failure(FailureType.notFound));
    });

    test('a malformed id is notFound without hitting the network', () async {
      await expectLater(repo.fetchDestination('not-a-uuid'), failure(FailureType.notFound));
      await expectLater(repo.fetchPackages("'; drop table x; --"), failure(FailureType.notFound));
      expect(requests, isEmpty);
    });

    test('storage paths are resolved to public bucket URLs; absolute URLs are kept', () async {
      respond = (_) => json([
            {
              ...destinationDetailsRow(),
              'id': cairoId,
              'cover_image': 'cairo/cover.jpg',
              'gallery': ['https://example.org/a.jpg', 'cairo/b.jpg'],
            },
          ]);
      final d = await repo.fetchDestination(cairoId);
      expect(
          d.coverImage, 'https://test-project.supabase.co/storage/v1/object/public/destination-images/cairo/cover.jpg');
      expect(d.gallery.first, 'https://example.org/a.jpg');
      expect(d.gallery.last, endsWith('/destination-images/cairo/b.jpg'));
    });

    test('fetchPackages filters by destination and orders', () async {
      respond = (_) => json([packageRow(destinationId: cairoId)]);
      final packages = await repo.fetchPackages(cairoId);

      expect(packages.single.durationDays, 4);
      final uri = requests.single.url;
      expect(uri.path, '/rest/v1/destination_packages');
      expect(uri.queryParameters['destination_id'], 'eq.$cairoId');
      // postgrest-dart defaults to descending; packages must be cheapest/first-sorted.
      expect(uri.queryParameters['order'], matches(RegExp(r'^sort_order.asc[^,]*,price_per_person.asc')));
    });

    test('fetchDestinations lists featured first, then names A→Z', () async {
      respond = (_) => json([destinationRow()]);
      await repo.fetchDestinations();
      final uri = requests.single.url;
      expect(uri.path, '/rest/v1/destination_summaries');
      expect(uri.queryParameters['order'], matches(RegExp(r'^is_featured.desc[^,]*,name_en.asc')));
    });

    test('fetchDestinationsByIds keeps the requested order and skips unknown ids', () async {
      const kyotoId = '1c2d3e4f-5a6b-4c7d-8e9f-0a1b2c3d4e5f';
      respond = (_) => json([
            {...destinationRow(), 'id': cairoId},
            {...destinationRow(slug: 'kyoto'), 'id': kyotoId},
          ]);
      final list = await repo.fetchDestinationsByIds([kyotoId, 'bad-id', cairoId]);
      expect(list.map((d) => d.id), [kyotoId, cairoId]);
      expect(requests.single.url.queryParameters['id'], 'in.("$kyotoId","$cairoId")');
    });

    test('server errors are mapped, never leaked raw', () async {
      respond = (_) => json({'code': '42501', 'message': 'permission denied for table destinations'}, status: 403);
      await expectLater(repo.fetchDestination(cairoId), failure(FailureType.permissionDenied));

      respond = (_) => throw http.ClientException('Failed host lookup: test-project.supabase.co');
      await expectLater(repo.fetchPackages(cairoId), failure(FailureType.network));
    });
  });

  group('SupabaseFavoritesRepository', () {
    late String? signedInUser;
    late SupabaseFavoritesRepository repo;
    setUp(() {
      signedInUser = userId;
      repo = SupabaseFavoritesRepository(client, currentUserId: () => signedInUser);
    });

    test('fetchFavoriteIds reads only destination ids, newest first (RLS scopes the rows)', () async {
      respond = (_) => json([
            {'destination_id': cairoId},
          ]);
      expect(await repo.fetchFavoriteIds(), [cairoId]);
      final uri = requests.single.url;
      expect(uri.path, '/rest/v1/favorites');
      expect(uri.queryParameters['select'], 'destination_id');
      expect(uri.queryParameters['order'], startsWith('created_at.desc'));
    });

    test('addFavorite inserts only the destination id — never a user id', () async {
      respond = (_) => http.Response('', 201);
      await repo.addFavorite(cairoId);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/favorites');
      final body = jsonDecode(request.body);
      expect(body, {'destination_id': cairoId});
    });

    test('adding an existing favourite (23505) is treated as success', () async {
      respond = (_) => json({'code': '23505', 'message': 'duplicate key value'}, status: 409);
      await repo.addFavorite(cairoId);
    });

    test('adding a destination that does not exist (23503) is notFound', () async {
      respond = (_) => json({'code': '23503', 'message': 'violates foreign key constraint'}, status: 409);
      await expectLater(repo.addFavorite(cairoId), failure(FailureType.notFound));
    });

    test('an RLS rejection is reported, not swallowed', () async {
      respond = (_) => json({'code': '42501', 'message': 'new row violates row-level security policy'}, status: 403);
      await expectLater(repo.addFavorite(cairoId), failure(FailureType.permissionDenied));
    });

    test('removeFavorite deletes only the caller\'s row for that destination', () async {
      respond = (_) => http.Response('', 204);
      await repo.removeFavorite(cairoId);

      final request = requests.single;
      expect(request.method, 'DELETE');
      expect(request.url.queryParameters['user_id'], 'eq.$userId');
      expect(request.url.queryParameters['destination_id'], 'eq.$cairoId');
    });

    test('without a session nothing is sent', () async {
      signedInUser = null;
      await expectLater(repo.fetchFavoriteIds(), failure(FailureType.sessionExpired));
      await expectLater(repo.addFavorite(cairoId), failure(FailureType.sessionExpired));
      await expectLater(repo.removeFavorite(cairoId), failure(FailureType.sessionExpired));
      expect(requests, isEmpty);
    });

    test('an expired JWT maps to sessionExpired', () async {
      respond = (_) => json({'code': 'PGRST301', 'message': 'JWT expired'}, status: 401);
      await expectLater(repo.fetchFavoriteIds(), failure(FailureType.sessionExpired));
    });
  });
}
