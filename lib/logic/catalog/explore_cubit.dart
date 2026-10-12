import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/text_search.dart';
import '../../data/models/catalog_models.dart';

/// Trip length buckets, from each destination's package durations
/// (`min_days` … `max_days` in `destination_summaries`).
enum TripLength {
  short(1, 3),
  medium(4, 6),
  long(7, 365);

  const TripLength(this.minDays, this.maxDays);
  final int minDays;
  final int maxDays;

  /// A destination matches if any of its packages could fall in the bucket.
  bool matches(DestinationSummary d) =>
      d.minDays != null && d.maxDays != null && d.minDays! <= maxDays && d.maxDays! >= minDays;
}

enum ExploreSort { featured, priceLowToHigh, priceHighToLow, name }

class ExploreFilters extends Equatable {
  const ExploreFilters({
    this.categoryId,
    this.maxPrice,
    this.lengths = const {},
    this.sort = ExploreSort.featured,
  });

  final String? categoryId;

  /// Upper bound for the "from" price per person; `null` = any.
  final double? maxPrice;
  final Set<TripLength> lengths;
  final ExploreSort sort;

  /// Filters beyond category and sort (shown as a count on the button).
  int get activeCount => (maxPrice != null ? 1 : 0) + (lengths.isNotEmpty ? 1 : 0);

  ExploreFilters copyWith({
    String? Function()? categoryId,
    double? Function()? maxPrice,
    Set<TripLength>? lengths,
    ExploreSort? sort,
  }) =>
      ExploreFilters(
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        lengths: lengths ?? this.lengths,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [categoryId, maxPrice, lengths, sort];
}

/// Pure filter + sort over the loaded catalog. Search matches name, country
/// and summary in BOTH English and Arabic, whatever the UI language.
/// Destinations without packages never match a price or length filter.
List<DestinationSummary> exploreResults(
  List<DestinationSummary> all,
  String query,
  ExploreFilters filters, {
  String languageCode = 'en',
}) {
  final results = all.where((d) {
    if (filters.categoryId != null && d.categoryId != filters.categoryId) return false;
    if (filters.maxPrice != null && (d.fromPrice == null || d.fromPrice! > filters.maxPrice!)) return false;
    if (filters.lengths.isNotEmpty && !filters.lengths.any((l) => l.matches(d))) return false;
    return matchesAllWords(
      [d.nameEn, d.nameAr, d.countryEn, d.countryAr, d.summaryEn, d.summaryAr].join(' '),
      query,
    );
  }).toList();

  int byName(DestinationSummary a, DestinationSummary b) => a.name(languageCode).compareTo(b.name(languageCode));
  int price(DestinationSummary d, {required bool high}) => (d.fromPrice ?? (high ? -1 : double.maxFinite)).round();
  switch (filters.sort) {
    case ExploreSort.featured:
      results.sort((a, b) => a.isFeatured == b.isFeatured ? byName(a, b) : (a.isFeatured ? -1 : 1));
    case ExploreSort.priceLowToHigh:
      results.sort((a, b) {
        final c = price(a, high: false).compareTo(price(b, high: false));
        return c != 0 ? c : byName(a, b);
      });
    case ExploreSort.priceHighToLow:
      results.sort((a, b) {
        final c = price(b, high: true).compareTo(price(a, high: true));
        return c != 0 ? c : byName(a, b);
      });
    case ExploreSort.name:
      results.sort(byName);
  }
  return results;
}

class ExploreState extends Equatable {
  const ExploreState({this.query = '', this.filters = const ExploreFilters()});

  /// The applied (debounced) query.
  final String query;
  final ExploreFilters filters;

  bool get isFiltering => query.trim().isNotEmpty || filters.categoryId != null || filters.activeCount > 0;

  ExploreState copyWith({String? query, ExploreFilters? filters}) =>
      ExploreState(query: query ?? this.query, filters: filters ?? this.filters);

  @override
  List<Object?> get props => [query, filters];
}

/// Search text + filters for Explore. Results are computed from the shared
/// catalog with [exploreResults] — synchronously, so there are no request
/// races; typing is debounced only to avoid re-sorting on every keystroke.
class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit({this.debounce = const Duration(milliseconds: 250), String? initialCategoryId})
      : super(ExploreState(filters: ExploreFilters(categoryId: initialCategoryId)));

  final Duration debounce;
  Timer? _timer;

  void typeQuery(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (!isClosed && text != state.query) emit(state.copyWith(query: text));
    });
  }

  /// Applies immediately (submit / clear).
  void setQuery(String text) {
    _timer?.cancel();
    emit(state.copyWith(query: text));
  }

  void selectCategory(String? categoryId) =>
      emit(state.copyWith(filters: state.filters.copyWith(categoryId: () => categoryId)));

  void applyFilters(ExploreFilters filters) => emit(state.copyWith(filters: filters));

  void clearAll() {
    _timer?.cancel();
    emit(const ExploreState());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
