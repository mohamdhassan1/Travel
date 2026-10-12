import 'package:equatable/equatable.dart';

import 'json_read.dart';

/// A row of `public.categories`.
class TravelCategory extends Equatable {
  const TravelCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.sortOrder,
  });

  factory TravelCategory.fromJson(Map<String, dynamic> json) => TravelCategory(
        id: json.str('id'),
        nameEn: json.str('name_en'),
        nameAr: json.str('name_ar'),
        icon: json.str('icon'),
        sortOrder: json.intOrNull('sort_order') ?? 0,
      );

  final String id;
  final String nameEn;
  final String nameAr;

  /// Icon key (e.g. `heritage`); the UI maps it to an icon.
  final String icon;
  final int sortOrder;

  String name(String languageCode) => pickLocalized(languageCode, en: nameEn, ar: nameAr);

  @override
  List<Object?> get props => [id, nameEn, nameAr, icon, sortOrder];
}

/// A row of the `public.destination_summaries` view: card-level destination
/// data plus a server-computed "from" price across its active packages.
class DestinationSummary extends Equatable {
  const DestinationSummary({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.countryEn,
    required this.countryAr,
    required this.summaryEn,
    required this.summaryAr,
    required this.coverImage,
    required this.isFeatured,
    required this.latitude,
    required this.longitude,
    this.fromPrice,
    this.currency,
    this.minDays,
    this.maxDays,
    this.packageCount = 0,
  });

  factory DestinationSummary.fromJson(Map<String, dynamic> json) => DestinationSummary(
        id: json.str('id'),
        slug: json.str('slug'),
        categoryId: json.str('category_id'),
        nameEn: json.str('name_en'),
        nameAr: json.str('name_ar'),
        countryEn: json.str('country_en'),
        countryAr: json.str('country_ar'),
        summaryEn: json.str('summary_en'),
        summaryAr: json.str('summary_ar'),
        coverImage: json.str('cover_image'),
        isFeatured: json.boolean('is_featured'),
        latitude: json.number('latitude'),
        longitude: json.number('longitude'),
        fromPrice: json.numOrNull('from_price'),
        currency: json.strOrNull('currency')?.trim(),
        minDays: json.intOrNull('min_days'),
        maxDays: json.intOrNull('max_days'),
        packageCount: json.intOrNull('package_count') ?? 0,
      );

  final String id;
  final String slug;
  final String categoryId;
  final String nameEn;
  final String nameAr;
  final String countryEn;
  final String countryAr;
  final String summaryEn;
  final String summaryAr;

  /// Absolute URL or an object path in the `destination-images` bucket.
  final String coverImage;
  final bool isFeatured;
  final double latitude;
  final double longitude;

  /// Lowest active package price per person; `null` when no packages exist.
  final double? fromPrice;
  final String? currency;
  final int? minDays;
  final int? maxDays;
  final int packageCount;

  bool get hasPackages => packageCount > 0 && fromPrice != null && currency != null;

  String name(String languageCode) => pickLocalized(languageCode, en: nameEn, ar: nameAr);
  String country(String languageCode) => pickLocalized(languageCode, en: countryEn, ar: countryAr);
  String summary(String languageCode) => pickLocalized(languageCode, en: summaryEn, ar: summaryAr);

  @override
  List<Object?> get props => [
        id,
        slug,
        categoryId,
        nameEn,
        coverImage,
        fromPrice,
        packageCount,
        isFeatured,
      ];
}

/// A full row of `public.destinations`, used by the details screen.
///
/// Mirrors the schema exactly: there is no city, rating or review data, so
/// none is modelled.
class DestinationDetails extends Equatable {
  const DestinationDetails({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.countryEn,
    required this.countryAr,
    required this.summaryEn,
    required this.summaryAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.latitude,
    required this.longitude,
    required this.coverImage,
    this.bestSeasonEn,
    this.bestSeasonAr,
    this.gallery = const [],
    this.imageCredit,
    this.isFeatured = false,
  });

  factory DestinationDetails.fromJson(Map<String, dynamic> json) => DestinationDetails(
        id: json.str('id'),
        slug: json.str('slug'),
        categoryId: json.str('category_id'),
        nameEn: json.str('name_en'),
        nameAr: json.str('name_ar'),
        countryEn: json.str('country_en'),
        countryAr: json.str('country_ar'),
        summaryEn: json.str('summary_en'),
        summaryAr: json.str('summary_ar'),
        descriptionEn: json.str('description_en'),
        descriptionAr: json.str('description_ar'),
        bestSeasonEn: json.strOrNull('best_season_en'),
        bestSeasonAr: json.strOrNull('best_season_ar'),
        latitude: json.number('latitude'),
        longitude: json.number('longitude'),
        coverImage: json.str('cover_image'),
        gallery: json.strList('gallery'),
        imageCredit: json.strOrNull('image_credit'),
        isFeatured: json.boolean('is_featured'),
      );

  final String id;
  final String slug;
  final String categoryId;
  final String nameEn;
  final String nameAr;
  final String countryEn;
  final String countryAr;
  final String summaryEn;
  final String summaryAr;
  final String descriptionEn;
  final String descriptionAr;
  final String? bestSeasonEn;
  final String? bestSeasonAr;
  final double latitude;
  final double longitude;

  /// Resolved absolute URL (see `CatalogRepository`).
  final String coverImage;

  /// Resolved absolute URLs of additional photos.
  final List<String> gallery;

  /// Photographer / licence attribution for the photos.
  final String? imageCredit;
  final bool isFeatured;

  String name(String languageCode) => pickLocalized(languageCode, en: nameEn, ar: nameAr);
  String country(String languageCode) => pickLocalized(languageCode, en: countryEn, ar: countryAr);
  String summary(String languageCode) => pickLocalized(languageCode, en: summaryEn, ar: summaryAr);
  String description(String languageCode) => pickLocalized(languageCode, en: descriptionEn, ar: descriptionAr);

  String? bestSeason(String languageCode) {
    final en = bestSeasonEn;
    final ar = bestSeasonAr;
    if (en == null && ar == null) return null;
    return pickLocalized(languageCode, en: en ?? ar!, ar: ar ?? en!);
  }

  @override
  List<Object?> get props => [id, slug, nameEn, nameAr, coverImage, gallery, imageCredit];
}

/// A row of `public.destination_packages` (active packages only are visible
/// through RLS).
class TravelPackage extends Equatable {
  const TravelPackage({
    required this.id,
    required this.destinationId,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.durationDays,
    required this.pricePerPerson,
    required this.currency,
    required this.maxTravelers,
    this.includesEn = const [],
    this.includesAr = const [],
    this.sortOrder = 0,
  });

  factory TravelPackage.fromJson(Map<String, dynamic> json) {
    final duration = json.intOrNull('duration_days');
    final maxTravelers = json.intOrNull('max_travelers');
    if (duration == null || duration < 1) throw FormatException('Invalid duration_days', json['duration_days']);
    if (maxTravelers == null || maxTravelers < 1) throw FormatException('Invalid max_travelers', json['max_travelers']);
    final price = json.number('price_per_person');
    if (price <= 0) throw FormatException('Invalid price_per_person', price);
    return TravelPackage(
      id: json.str('id'),
      destinationId: json.str('destination_id'),
      nameEn: json.str('name_en'),
      nameAr: json.str('name_ar'),
      descriptionEn: json.str('description_en'),
      descriptionAr: json.str('description_ar'),
      durationDays: duration,
      pricePerPerson: price,
      // char(3) may come back padded.
      currency: json.str('currency').trim(),
      maxTravelers: maxTravelers,
      includesEn: json.strList('includes_en'),
      includesAr: json.strList('includes_ar'),
      sortOrder: json.intOrNull('sort_order') ?? 0,
    );
  }

  final String id;
  final String destinationId;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final int durationDays;
  final double pricePerPerson;
  final String currency;
  final int maxTravelers;
  final List<String> includesEn;
  final List<String> includesAr;
  final int sortOrder;

  String name(String languageCode) => pickLocalized(languageCode, en: nameEn, ar: nameAr);
  String description(String languageCode) => pickLocalized(languageCode, en: descriptionEn, ar: descriptionAr);

  /// Falls back to the other language if one list is missing.
  List<String> includes(String languageCode) {
    final primary = languageCode == 'ar' ? includesAr : includesEn;
    return primary.isNotEmpty ? primary : (languageCode == 'ar' ? includesEn : includesAr);
  }

  @override
  List<Object?> get props => [id, destinationId, nameEn, durationDays, pricePerPerson, currency, maxTravelers];
}
