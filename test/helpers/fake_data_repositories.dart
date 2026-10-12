import 'dart:async';
import 'dart:typed_data';

import 'package:rahala/core/errors/app_failure.dart';
import 'package:rahala/data/models/catalog_models.dart';
import 'package:rahala/data/models/user_profile.dart';
import 'package:rahala/data/repositories/catalog_repository.dart';
import 'package:rahala/data/repositories/favorites_repository.dart';
import 'package:rahala/data/repositories/profile_repository.dart';

Map<String, dynamic> destinationRow({
  String slug = 'cairo',
  String nameEn = 'Cairo',
  bool featured = true,
  Object? fromPrice = 180,
  int packageCount = 2,
}) =>
    {
      'id': 'id-$slug',
      'slug': slug,
      'category_id': 'heritage',
      'name_en': nameEn,
      'name_ar': 'القاهرة',
      'country_en': 'Egypt',
      'country_ar': 'مصر',
      'summary_en': 'Pyramids and the Nile.',
      'summary_ar': 'الأهرامات والنيل.',
      // Unroutable test URL: images fall back to their error placeholder.
      'cover_image': 'https://example.invalid/$slug.jpg',
      'is_featured': featured,
      'latitude': 30.04,
      'longitude': 31.23,
      'created_at': '2026-10-01T00:00:00Z',
      'from_price': fromPrice,
      'currency': packageCount == 0 ? null : 'USD',
      'min_days': packageCount == 0 ? null : 2,
      'max_days': packageCount == 0 ? null : 4,
      'package_count': packageCount,
    };

/// A full `destinations` row.
Map<String, dynamic> destinationDetailsRow({String slug = 'cairo', String nameEn = 'Cairo'}) => {
      'id': 'id-$slug',
      'slug': slug,
      'category_id': 'heritage',
      'name_en': nameEn,
      'name_ar': 'القاهرة',
      'country_en': 'Egypt',
      'country_ar': 'مصر',
      'summary_en': 'Pyramids and the Nile.',
      'summary_ar': 'الأهرامات والنيل.',
      'description_en': 'Egypt\'s capital pairs the Giza plateau with Islamic Cairo.',
      'description_ar': 'تجمع عاصمة مصر بين هضبة الجيزة والقاهرة الإسلامية.',
      'best_season_en': 'October – April',
      'best_season_ar': 'أكتوبر – أبريل',
      'latitude': 30.0444,
      'longitude': 31.2357,
      'cover_image': 'https://example.invalid/$slug.jpg',
      'gallery': ['https://example.invalid/$slug-1.jpg', 'https://example.invalid/$slug-2.jpg'],
      'image_credit': 'Wikimedia Commons: Test Photographer (CC BY-SA 4.0)',
      'is_featured': true,
      'is_published': true,
      'created_at': '2026-10-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
    };

/// A `destination_packages` row.
Map<String, dynamic> packageRow({
  String id = 'pkg-1',
  String destinationId = 'id-cairo',
  String nameEn = 'Pyramids & Old Cairo Discovery',
  String nameAr = 'اكتشاف الأهرامات والقاهرة القديمة',
  Object price = 420,
  int days = 4,
}) =>
    {
      'id': id,
      'destination_id': destinationId,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description_en': 'Four days with a licensed Egyptologist.',
      'description_ar': 'أربعة أيام برفقة مرشد أثري مرخّص.',
      'duration_days': days,
      'price_per_person': price,
      'currency': 'USD',
      'max_travelers': 8,
      'includes_en': ['3 nights hotel with breakfast', 'Airport transfers'],
      'includes_ar': ['٣ ليالٍ في فندق مع الإفطار', 'التنقل من وإلى المطار'],
      'is_active': true,
      'sort_order': 1,
    };

final sampleCategories = [
  for (final (i, id, en, ar) in [
    (1, 'heritage', 'Heritage', 'تراث وتاريخ'),
    (2, 'city', 'Cities', 'مدن'),
    (3, 'beach', 'Beaches', 'شواطئ'),
    (4, 'islands', 'Islands', 'جزر'),
  ])
    TravelCategory.fromJson(
        {'id': id, 'name_en': en, 'name_ar': ar, 'icon': id == 'city' ? 'city' : id, 'sort_order': i}),
];

final sampleDestinations = [
  DestinationSummary.fromJson(destinationRow()),
  DestinationSummary.fromJson(destinationRow(slug: 'kyoto', nameEn: 'Kyoto', featured: false, fromPrice: 720)),
];

final sampleDetails = {
  'id-cairo': DestinationDetails.fromJson(destinationDetailsRow()),
  'id-kyoto': DestinationDetails.fromJson(destinationDetailsRow(slug: 'kyoto', nameEn: 'Kyoto')),
};

final samplePackages = {
  'id-cairo': [
    TravelPackage.fromJson(packageRow()),
    TravelPackage.fromJson(packageRow(
        id: 'pkg-2', nameEn: 'Cairo Weekend Escape', nameAr: 'عطلة نهاية الأسبوع في القاهرة', price: 180, days: 2)),
  ],
};

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    List<DestinationSummary>? destinations,
    Map<String, DestinationDetails>? details,
    Map<String, List<TravelPackage>>? packages,
  })  : destinations = destinations ?? sampleDestinations,
        details = details ?? sampleDetails,
        packages = packages ?? samplePackages;

  List<DestinationSummary> destinations;
  Map<String, DestinationDetails> details;
  Map<String, List<TravelPackage>> packages;

  AppFailure? nextFailure;
  AppFailure? nextDetailsFailure;
  AppFailure? nextPackagesFailure;
  Completer<void>? gate;
  int destinationCalls = 0;
  final byIdCalls = <List<String>>[];

  T _consume<T extends Object>(AppFailure? Function() read, void Function() clear, T value) {
    final failure = read();
    if (failure != null) {
      clear();
      throw failure;
    }
    return value;
  }

  List<TravelCategory> categories = sampleCategories;

  @override
  Future<List<TravelCategory>> fetchCategories() async => categories;

  @override
  Future<List<DestinationSummary>> fetchDestinations({String? categoryId}) async {
    destinationCalls++;
    await gate?.future;
    return _consume(() => nextFailure, () => nextFailure = null, destinations);
  }

  @override
  Future<List<DestinationSummary>> fetchDestinationsByIds(List<String> ids) async {
    byIdCalls.add(ids);
    final byId = {for (final d in destinations) d.id: d};
    return _consume(() => nextFailure, () => nextFailure = null, [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ]);
  }

  @override
  Future<DestinationDetails> fetchDestination(String id) async {
    final failure = nextDetailsFailure;
    if (failure != null) {
      nextDetailsFailure = null;
      throw failure;
    }
    return details[id] ?? (throw const AppFailure(FailureType.notFound));
  }

  @override
  Future<List<TravelPackage>> fetchPackages(String destinationId) async =>
      _consume(() => nextPackagesFailure, () => nextPackagesFailure = null, packages[destinationId] ?? []);
}

/// Behaves like the `favorites` table under RLS: one set per signed-in user.
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({String? Function()? currentUserId, Map<String, List<String>>? initial})
      : _currentUserId = currentUserId ?? (() => 'user-1'),
        _byUser = {
          for (final e in (initial ?? {}).entries) e.key: [...e.value]
        };

  final String? Function() _currentUserId;
  final Map<String, List<String>> _byUser;

  AppFailure? nextLoadFailure;
  AppFailure? nextWriteFailure;
  Completer<void>? writeGate;
  final calls = <String>[];

  List<String> idsFor(String userId) => List.unmodifiable(_byUser[userId] ?? const []);

  String _user() => _currentUserId() ?? (throw const AppFailure(FailureType.sessionExpired));

  @override
  Future<List<String>> fetchFavoriteIds() async {
    final user = _user();
    calls.add('load:$user');
    final failure = nextLoadFailure;
    if (failure != null) {
      nextLoadFailure = null;
      throw failure;
    }
    return [...?_byUser[user]];
  }

  @override
  Future<void> addFavorite(String destinationId) async {
    final user = _user();
    calls.add('add:$destinationId');
    await writeGate?.future;
    _throwWriteFailure();
    final list = _byUser.putIfAbsent(user, () => []);
    if (!list.contains(destinationId)) list.insert(0, destinationId);
  }

  @override
  Future<void> removeFavorite(String destinationId) async {
    final user = _user();
    calls.add('remove:$destinationId');
    await writeGate?.future;
    _throwWriteFailure();
    _byUser[user]?.remove(destinationId);
  }

  void _throwWriteFailure() {
    final failure = nextWriteFailure;
    if (failure != null) {
      nextWriteFailure = null;
      throw failure;
    }
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({UserProfile? profile, Map<String, UserProfile>? profiles, String? Function()? currentUserId})
      : _currentUserId = currentUserId ?? (() => 'user-1'),
        _profiles = {
          ...?profiles,
          if (profile != null) profile.id: profile,
          if (profile == null && profiles == null) 'user-1': const UserProfile(id: 'user-1', fullName: 'Sara Ali'),
        };

  final String? Function() _currentUserId;
  final Map<String, UserProfile> _profiles;

  /// Objects in the private avatars bucket (path → bytes length).
  final storage = <String, int>{};
  AppFailure? nextFailure;
  AppFailure? nextWriteFailure;
  final calls = <String>[];
  int _seq = 0;

  UserProfile get profile => _profiles[_user()]!;
  set profile(UserProfile p) => _profiles[p.id] = p;
  UserProfile profileOf(String userId) => _profiles[userId]!;

  String _user() => _currentUserId() ?? (throw const AppFailure(FailureType.sessionExpired));

  void _fail([bool write = false]) {
    final failure = write ? nextWriteFailure : nextFailure;
    if (failure != null) {
      if (write) {
        nextWriteFailure = null;
      } else {
        nextFailure = null;
      }
      throw failure;
    }
  }

  UserProfile _copy(UserProfile p, {String? fullName, String? Function()? phone, String? Function()? avatarPath}) =>
      UserProfile(
        id: p.id,
        fullName: fullName ?? p.fullName,
        phone: phone != null ? phone() : p.phone,
        avatarPath: avatarPath != null ? avatarPath() : p.avatarPath,
        preferredLocale: p.preferredLocale,
        createdAt: p.createdAt,
      );

  @override
  Future<UserProfile> fetchMyProfile() async {
    final user = _user();
    calls.add('load:$user');
    _fail();
    return _profiles[user] ?? (throw const AppFailure(FailureType.notFound));
  }

  @override
  Future<UserProfile> updateProfile({required String fullName, String? phone}) async {
    final user = _user();
    calls.add('update:$user');
    _fail(true);
    final name = fullName.trim();
    final p = phone?.trim();
    // Mirrors the CHECK constraints.
    if (name.length > 80) throw const AppFailure(FailureType.invalidInput);
    if (p != null && p.isNotEmpty && !RegExp(r'^\+?[0-9 ()-]{6,20}$').hasMatch(p)) {
      throw const AppFailure(FailureType.invalidInput);
    }
    return _profiles[user] = _copy(_profiles[user]!, fullName: name, phone: () => (p == null || p.isEmpty) ? null : p);
  }

  @override
  Future<UserProfile> uploadAvatar(Uint8List bytes, String contentType) async {
    final user = _user();
    calls.add('upload:$user');
    _fail(true);
    final path = '$user/avatar-${++_seq}.jpg';
    storage[path] = bytes.length;
    final previous = _profiles[user]!.avatarPath;
    final updated = _profiles[user] = _copy(_profiles[user]!, avatarPath: () => path);
    if (previous != null) storage.remove(previous);
    return updated;
  }

  @override
  Future<UserProfile> removeAvatar() async {
    final user = _user();
    calls.add('remove:$user');
    _fail(true);
    final previous = _profiles[user]!.avatarPath;
    final updated = _profiles[user] = _copy(_profiles[user]!, avatarPath: () => null);
    if (previous != null) storage.remove(previous);
    return updated;
  }

  @override
  Future<String> avatarUrl(String path) async {
    final user = _user();
    if (!path.startsWith('$user/')) throw const AppFailure(FailureType.permissionDenied);
    if (!storage.containsKey(path)) throw const AppFailure(FailureType.notFound);
    return 'https://example.invalid/signed/$path';
  }
}
