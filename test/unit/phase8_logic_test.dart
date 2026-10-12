import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/core/utils/text_search.dart';
import 'package:rahala/data/models/app_user.dart';
import 'package:rahala/data/models/booking.dart';
import 'package:rahala/data/models/catalog_models.dart';
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/data/repositories/recently_viewed_store.dart';
import 'package:rahala/data/repositories/weather_repository.dart';
import 'package:rahala/logic/auth/session_cubit.dart';
import 'package:rahala/logic/booking/my_bookings_cubit.dart';
import 'package:rahala/logic/booking/observable_booking_repository.dart';
import 'package:rahala/logic/catalog/catalog_cubit.dart';
import 'package:rahala/logic/catalog/explore_cubit.dart';
import 'package:rahala/logic/catalog/recently_viewed_cubit.dart';
import 'package:rahala/logic/common/load_state.dart';
import 'package:rahala/logic/profile/profile_cubit.dart';
import 'package:rahala/logic/profile/travel_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_booking_repository.dart';
import '../helpers/fake_data_repositories.dart';
import 'booking_model_test.dart' show bookingRow;

DestinationSummary dest(
  String slug, {
  String nameEn = 'X',
  String nameAr = 'س',
  String countryEn = 'Egypt',
  String countryAr = 'مصر',
  String category = 'heritage',
  bool featured = false,
  double? fromPrice = 500,
  int? minDays = 3,
  int? maxDays = 5,
}) =>
    DestinationSummary.fromJson({
      ...destinationRow(slug: slug, nameEn: nameEn, featured: featured),
      'name_ar': nameAr,
      'country_en': countryEn,
      'country_ar': countryAr,
      'category_id': category,
      'from_price': fromPrice,
      'currency': fromPrice == null ? null : 'USD',
      'min_days': minDays,
      'max_days': maxDays,
      'package_count': fromPrice == null ? 0 : 2,
    });

void main() {
  group('normalizeForSearch / matchesAllWords', () {
    test('case, Latin accents, Arabic marks and letter forms', () {
      expect(normalizeForSearch('Türkiye  ÇAĞ'), 'turkiye cag');
      expect(normalizeForSearch('القَاهِرَة'), 'القاهره');
      expect(normalizeForSearch('إسطنبول'), normalizeForSearch('اسطنبول'));
      expect(normalizeForSearch('مكتبة'), normalizeForSearch('مكتبه'));
      expect(normalizeForSearch('مستشفى'), normalizeForSearch('مستشفي'));
      expect(normalizeForSearch('ـــجــزر'), 'جزر');
    });

    test('every word must match, in any order', () {
      expect(matchesAllWords('Santorini Greece islands', 'greece santo'), isTrue);
      expect(matchesAllWords('Santorini Greece', 'greece paris'), isFalse);
      expect(matchesAllWords('anything', '   '), isTrue);
    });
  });

  group('exploreResults', () {
    final all = [
      dest('cairo', nameEn: 'Cairo', nameAr: 'القاهرة', featured: true, fromPrice: 180, minDays: 2, maxDays: 4),
      dest('paris',
          nameEn: 'Paris', nameAr: 'باريس', countryEn: 'France', countryAr: 'فرنسا', category: 'city', fromPrice: 900),
      dest('maldives',
          nameEn: 'Maldives',
          nameAr: 'جزر المالديف',
          countryEn: 'Maldives',
          countryAr: 'المالديف',
          category: 'islands',
          featured: true,
          fromPrice: 1450,
          minDays: 5,
          maxDays: 7),
      dest('kyoto',
          nameEn: 'Kyoto',
          nameAr: 'كيوتو',
          countryEn: 'Japan',
          countryAr: 'اليابان',
          fromPrice: null,
          minDays: null,
          maxDays: null),
    ];
    List<String> slugs(List<DestinationSummary> r) => [for (final d in r) d.slug];

    test('search matches English and Arabic, whatever the UI language', () {
      expect(slugs(exploreResults(all, 'cairo', const ExploreFilters())), ['cairo']);
      expect(slugs(exploreResults(all, 'القاهره', const ExploreFilters())), ['cairo'], reason: 'ة vs ه');
      expect(slugs(exploreResults(all, 'france', const ExploreFilters(), languageCode: 'ar')), ['paris']);
      expect(exploreResults(all, 'atlantis', const ExploreFilters()), isEmpty);
    });

    test('category, max price and trip length; destinations without packages never match price/length', () {
      expect(slugs(exploreResults(all, '', const ExploreFilters(categoryId: 'islands'))), ['maldives']);
      expect(slugs(exploreResults(all, '', const ExploreFilters(maxPrice: 900, sort: ExploreSort.name))),
          ['cairo', 'paris']);
      expect(slugs(exploreResults(all, '', const ExploreFilters(lengths: {TripLength.short}, sort: ExploreSort.name))),
          ['cairo', 'paris'],
          reason: 'ranges overlap 1–3 days');
      expect(slugs(exploreResults(all, '', const ExploreFilters(lengths: {TripLength.long}))), ['maldives']);
    });

    test('sorting', () {
      expect(slugs(exploreResults(all, '', const ExploreFilters())), ['cairo', 'maldives', 'kyoto', 'paris'],
          reason: 'featured first, then by name');
      expect(slugs(exploreResults(all, '', const ExploreFilters(sort: ExploreSort.priceLowToHigh))),
          ['cairo', 'paris', 'maldives', 'kyoto'],
          reason: 'no price last');
      expect(slugs(exploreResults(all, '', const ExploreFilters(sort: ExploreSort.priceHighToLow))),
          ['maldives', 'paris', 'cairo', 'kyoto']);
    });

    test('active filter count excludes category and sort', () {
      expect(const ExploreFilters(categoryId: 'x', sort: ExploreSort.name).activeCount, 0);
      expect(const ExploreFilters(maxPrice: 1, lengths: {TripLength.short}).activeCount, 2);
    });
  });

  group('ExploreCubit', () {
    test('typing is debounced: only the last text is applied', () async {
      final cubit = ExploreCubit(debounce: const Duration(milliseconds: 30));
      final applied = <String>[];
      final sub = cubit.stream.listen((s) => applied.add(s.query));
      cubit
        ..typeQuery('c')
        ..typeQuery('ca')
        ..typeQuery('cai');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(applied, ['cai']);
      cubit.setQuery(''); // clear applies at once
      expect(cubit.state.query, '');
      await sub.cancel();
      await cubit.close();
    });

    test('initial category, select and clear all', () async {
      final cubit = ExploreCubit(initialCategoryId: 'beach');
      expect(cubit.state.filters.categoryId, 'beach');
      cubit.selectCategory(null);
      expect(cubit.state.isFiltering, isFalse);
      cubit.applyFilters(const ExploreFilters(maxPrice: 300));
      expect(cubit.state.isFiltering, isTrue);
      cubit.clearAll();
      expect(cubit.state, const ExploreState());
      await cubit.close();
    });
  });

  group('CatalogCubit', () {
    test('loads categories and destinations once; concurrent loads share one request', () async {
      final repo = FakeCatalogRepository();
      final cubit = CatalogCubit(repo);
      await Future.wait([cubit.load(), cubit.load(), cubit.ensureLoaded()]);
      expect(cubit.state.isReady, isTrue);
      expect(cubit.state.destinations, hasLength(2));
      expect(cubit.state.featured.single.slug, 'cairo');
      expect(repo.destinationCalls, 1);
      await cubit.ensureLoaded();
      expect(repo.destinationCalls, 1, reason: 'already loaded');
      await cubit.close();
    });

    test('first-load failure, then a failed refresh keeps the data on screen', () async {
      final repo = FakeCatalogRepository()..nextFailure = const AppFailure(FailureType.network);
      final cubit = CatalogCubit(repo);
      await cubit.load();
      expect(cubit.state.status, CatalogStatus.failure);
      await cubit.load();
      expect(cubit.state.isReady, isTrue);
      repo.nextFailure = const AppFailure(FailureType.timeout);
      await cubit.load();
      expect(cubit.state.isReady, isTrue);
      expect(cubit.state.destinations, isNotEmpty);
      expect(cubit.state.failure?.type, FailureType.timeout);
      await cubit.close();
    });
  });

  group('TravelStats', () {
    final today = DateTime(2026, 10, 3);
    Booking b(String id, String date, {String status = 'confirmed', String country = 'Egypt', String dest = 'd1'}) =>
        Booking.fromJson({
          ...bookingRow(status: status, travelDate: date),
          'id': id,
          'destination_id': dest,
          'destination': {
            'id': dest,
            'name_en': 'X',
            'name_ar': 'س',
            'country_en': country,
            'country_ar': 'س',
            'cover_image': 'https://example.invalid/x.jpg',
          },
        });

    test('only real bookings count; cancelled never counts toward travel', () {
      final stats = TravelStats.from([
        b('1', '2026-05-01'),
        b('2', '2026-06-01', dest: 'd2', country: 'France'),
        b('3', '2026-06-10'), // same destination again
        b('4', '2026-12-01'),
        b('5', '2026-04-01', status: 'cancelled', dest: 'd9', country: 'Peru'),
      ], today);
      expect(stats.completedTrips, 3);
      expect(stats.upcomingTrips, 1);
      expect(stats.cancelledTrips, 1);
      expect(stats.destinationsVisited, 2);
      expect(stats.countriesVisited, 2);
      expect(stats.totalBookings, 5);
      expect(stats.travelersBooked, 12, reason: '3 travellers × 4 non-cancelled');
    });

    test('levels need both trips and countries; progress is the weaker requirement', () {
      expect(TravelStats.empty.level, TravelerLevel.newTraveler);
      final one = TravelStats.from([b('1', '2026-05-01')], today);
      expect(one.level, TravelerLevel.explorer);
      expect(one.tripsToNext, 2);
      expect(one.countriesToNext, 1);
      expect(one.progressToNext, closeTo(1 / 3, 0.001));

      // Many trips but one country: not a Voyager yet.
      final sameCountry =
          TravelStats.from([for (var i = 0; i < 5; i++) b('$i', '2026-0${i + 1}-02', dest: 'd$i')], today);
      expect(sameCountry.level, TravelerLevel.explorer);
      expect(sameCountry.countriesToNext, 1);

      final globe = TravelStats.from([
        for (var i = 0; i < 6; i++) b('$i', '2026-0${i + 1}-02', dest: 'd$i', country: ['A', 'B', 'C'][i % 3]),
      ], today);
      expect(globe.level, TravelerLevel.globetrotter);
      expect(globe.progressToNext, 1);
      expect(globe.level.next, isNull);
    });

    test('a trip today is upcoming, not completed', () {
      final stats = TravelStats.from([b('1', '2026-10-03')], today);
      expect(stats.upcomingTrips, 1);
      expect(stats.completedTrips, 0);
    });
  });

  group('ProfileCubit', () {
    const other = AppUser(id: 'user-2', email: 'other@example.com', fullName: 'Omar', emailConfirmed: true);
    late FakeAuthRepository auth;
    late SessionCubit session;
    late FakeProfileRepository repo;

    setUp(() {
      auth = FakeAuthRepository(signedInAs: testUser);
      session = SessionCubit(auth);
      repo = FakeProfileRepository(
        currentUserId: () => auth.currentUser?.id,
        profiles: {
          'user-1': const UserProfile(id: 'user-1', fullName: 'Sara Ali'),
          'user-2': const UserProfile(id: 'user-2', fullName: 'Omar Nabil', avatarPath: 'user-2/avatar-0.jpg'),
        },
      )..storage['user-2/avatar-0.jpg'] = 10;
    });

    tearDown(() async {
      await session.close();
      await auth.dispose();
    });

    Future<ProfileCubit> ready() async {
      final cubit = ProfileCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.isReady, isTrue);
      return cubit;
    }

    test('save: server row applied, phone cleared when blank, event emitted', () async {
      final cubit = await ready();
      expect(await cubit.save(fullName: '  Sara A. ', phone: ' +20 100 000 0000 '), isTrue);
      expect(cubit.state.profile!.fullName, 'Sara A.');
      expect(cubit.state.profile!.phone, '+20 100 000 0000');
      expect(cubit.state.lastEvent?.change, ProfileChange.saved);

      expect(await cubit.save(fullName: 'Sara A.', phone: ''), isTrue);
      expect(repo.profileOf('user-1').phone, isNull);
      await cubit.close();
    });

    test('a rejected save changes nothing and is reported', () async {
      final cubit = await ready();
      repo.nextWriteFailure = const AppFailure(FailureType.network);
      expect(await cubit.save(fullName: 'New Name'), isFalse);
      expect(cubit.state.profile!.fullName, 'Sara Ali');
      expect(cubit.state.lastEvent?.change, ProfileChange.saveFailed);
      expect(cubit.state.saving, isFalse);
      await cubit.close();
    });

    test('photo: upload replaces the old file, URL resolved; remove clears it', () async {
      final cubit = await ready();
      expect(cubit.state.avatarUrl, isNull);
      await cubit.changePhoto(Uint8List(100), 'image/jpeg');
      final path = repo.profileOf('user-1').avatarPath!;
      expect(path, startsWith('user-1/'));
      expect(cubit.state.avatarUrl, contains(path));
      expect(cubit.state.lastEvent?.change, ProfileChange.photoUpdated);

      await cubit.changePhoto(Uint8List(100), 'image/jpeg');
      expect(repo.storage.keys.where((k) => k.startsWith('user-1/')), hasLength(1), reason: 'old file deleted');

      await cubit.removePhoto();
      expect(repo.profileOf('user-1').avatarPath, isNull);
      expect(repo.storage.keys.where((k) => k.startsWith('user-1/')), isEmpty);
      expect(cubit.state.avatarUrl, isNull);
      await cubit.close();
    });

    test('too-large photos are refused before any upload; failures are reported', () async {
      final cubit = await ready();
      await cubit.changePhoto(Uint8List(2 * 1024 * 1024 + 1), 'image/jpeg');
      expect(cubit.state.lastEvent?.change, ProfileChange.photoTooLarge);
      expect(repo.calls.where((c) => c.startsWith('upload')), isEmpty);

      repo.nextWriteFailure = const AppFailure(FailureType.network);
      await cubit.changePhoto(Uint8List(10), 'image/jpeg');
      expect(cubit.state.lastEvent?.change, ProfileChange.photoFailed);
      expect(cubit.state.photoBusy, isFalse);
      await cubit.close();
    });

    test('a missing photo object falls back to initials', () async {
      repo.storage.clear();
      await auth.signOut();
      auth.switchTo(other);
      final cubit = ProfileCubit(repo, session);
      await pumpEventQueue();
      expect(cubit.state.profile!.avatarPath, isNotNull);
      expect(cubit.state.avatarUrl, isNull);
      await cubit.close();
    });

    test('account switch: never shows the previous user\'s name or photo', () async {
      final cubit = await ready();
      await cubit.changePhoto(Uint8List(10), 'image/jpeg');
      expect(cubit.state.avatarUrl, isNotNull);

      final after = <ProfileState>[];
      final sub = cubit.stream.listen(after.add);
      auth.switchTo(other);
      await pumpEventQueue();
      await sub.cancel();
      expect(after.first.profile, isNull, reason: 'cleared first');
      expect(after.first.avatarUrl, isNull);
      expect(after.any((s) => s.profile?.id == 'user-1' || (s.avatarUrl ?? '').contains('user-1/')), isFalse);
      expect(cubit.state.profile!.fullName, 'Omar Nabil');
      expect(cubit.state.avatarUrl, contains('user-2/'));

      await auth.signOut();
      await pumpEventQueue();
      expect(cubit.state.profile, isNull);
      expect(cubit.state.avatarUrl, isNull);
      await cubit.close();
    });
  });

  group('Recently viewed', () {
    test('newest first, deduplicated, capped, per account, survives a new cubit (restart)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = RecentlyViewedStore(await SharedPreferences.getInstance());
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final cubit = RecentlyViewedCubit(store, session);
      String id(int i) => '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';

      await cubit.record(id(1));
      await cubit.record(id(2));
      await cubit.record(id(1));
      expect(cubit.state, [id(1), id(2)]);
      await cubit.record('not-a-uuid');
      expect(cubit.state, hasLength(2));
      for (var i = 3; i < 20; i++) {
        await cubit.record(id(i));
      }
      expect(cubit.state, hasLength(RecentlyViewedStore.maxEntries));
      expect(cubit.state.first, id(19));

      final restarted = RecentlyViewedCubit(store, session);
      expect(restarted.state, cubit.state);

      auth.switchTo(const AppUser(id: 'user-2', email: 'o@example.com', emailConfirmed: true));
      await pumpEventQueue();
      expect(cubit.state, isEmpty, reason: 'another account has its own list');
      await auth.signOut();
      await pumpEventQueue();
      expect(cubit.state, isEmpty);

      await cubit.close();
      await restarted.close();
      await session.close();
      await auth.dispose();
    });
  });

  group('Weather', () {
    final body = {
      'current': {'time': '2026-10-03T14:00', 'temperature_2m': 27.6, 'weather_code': 2, 'is_day': 1},
      'daily': {
        'time': ['2026-10-03', '2026-10-04', '2026-10-05', '2026-10-06'],
        'weather_code': [0, 61, 95, 3],
        'temperature_2m_max': [30.1, 25, 22.2, 28],
        'temperature_2m_min': [20, 18.4, 17, 19],
      },
    };

    test('WMO codes map to coarse kinds', () {
      expect(weatherKindFor(0), WeatherKind.clear);
      expect(weatherKindFor(2), WeatherKind.partlyCloudy);
      expect(weatherKindFor(48), WeatherKind.fog);
      expect(weatherKindFor(55), WeatherKind.drizzle);
      expect(weatherKindFor(65), WeatherKind.rain);
      expect(weatherKindFor(86), WeatherKind.snow);
      expect(weatherKindFor(81), WeatherKind.showers);
      expect(weatherKindFor(99), WeatherKind.thunderstorm);
      expect(weatherKindFor(42), WeatherKind.unknown);
    });

    test('parses the Open-Meteo response; malformed payloads throw', () {
      final r = WeatherReport.fromJson(body);
      expect(r.temperatureC, 27.6);
      expect(r.kind, WeatherKind.partlyCloudy);
      expect(r.daily, hasLength(4));
      expect(r.daily[2].kind, WeatherKind.thunderstorm);
      expect(r.daily[1].minC, 18.4);
      expect(() => WeatherReport.fromJson(const {'current': {}}), throwsFormatException);
    });

    test('requests coordinates with timezone=auto, caches per location, maps errors', () async {
      final adapter = _Adapter((options) => ResponseBody.fromString(jsonEncode(body), 200, headers: {
            Headers.contentTypeHeader: ['application/json'],
          }));
      var now = DateTime(2026, 10, 3, 12);
      final repo = OpenMeteoWeatherRepository(
        dio: Dio(BaseOptions(baseUrl: 'https://api.open-meteo.com'))..httpClientAdapter = adapter,
        now: () => now,
      );
      await repo.fetch(30.0444, 31.2357);
      await repo.fetch(30.0444, 31.2357);
      expect(adapter.requests, hasLength(1), reason: 'cached');
      final q = adapter.requests.single.queryParameters;
      expect(q['latitude'], '30.0444');
      expect(q['timezone'], 'auto');
      now = now.add(const Duration(minutes: 31));
      await repo.fetch(30.0444, 31.2357);
      expect(adapter.requests, hasLength(2), reason: 'expired');

      final failing = OpenMeteoWeatherRepository(
        dio: Dio()
          ..httpClientAdapter = _Adapter((o) => throw DioException.connectionError(requestOptions: o, reason: 'x')),
      );
      await expectLater(
          failing.fetch(1, 2), throwsA(isA<AppFailure>().having((f) => f.type, 'type', FailureType.network)));
    });
  });

  group('Booking changes reach app-wide views', () {
    test('create and cancel are announced; MyBookingsCubit reloads', () async {
      final auth = FakeAuthRepository(signedInAs: testUser);
      final session = SessionCubit(auth);
      final inner = FakeBookingRepository(currentUserId: () => auth.currentUser?.id, today: DateTime(2026, 10));
      final repo = ObservableBookingRepository(inner);
      final changes = <Booking>[];
      repo.changes.listen(changes.add);
      final cubit = MyBookingsCubit(repo, session, changes: repo.changes);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);

      final created = await repo.createBooking(BookingRequest(
        destinationId: 'id-cairo',
        packageId: 'pkg-1',
        travelDate: DateTime(2026, 10, 20),
        travelers: 2,
        contactName: 'Sara Ali',
        contactPhone: '+20 100 000 0000',
      ));
      await pumpEventQueue();
      expect(changes.single.id, created.id);
      expect(cubit.state.data?.single.id, created.id);

      await repo.cancelBooking(created.id);
      await pumpEventQueue();
      expect(changes, hasLength(2));
      expect(cubit.state.data?.single.isCancelled, isTrue);

      await cubit.close();
      await repo.dispose();
      await session.close();
      await auth.dispose();
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
