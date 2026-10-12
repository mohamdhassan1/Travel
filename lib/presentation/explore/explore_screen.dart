import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_view.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/catalog/explore_cubit.dart';
import '../../routing/app_routes.dart';
import '../catalog/widgets/catalog_visuals.dart';
import '../common/l10n_extensions.dart';

/// Search + browse the catalog. Results are filtered on the device from the
/// shared catalog (small, already loaded), in English and Arabic at once.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key, this.categoryId, this.focusSearch = false});

  /// Pre-selected category (e.g. tapped on Home).
  final String? categoryId;
  final bool focusSearch;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ExploreCubit(initialCategoryId: categoryId),
        child: _ExploreView(categoryId: categoryId, focusSearch: focusSearch),
      );
}

class _ExploreView extends StatefulWidget {
  const _ExploreView({this.categoryId, required this.focusSearch});

  final String? categoryId;
  final bool focusSearch;

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<CatalogCubit>().ensureLoaded();
    if (widget.focusSearch) WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void didUpdateWidget(covariant _ExploreView old) {
    super.didUpdateWidget(old);
    // The tab stays alive; a new link (Home category / search) updates it.
    if (widget.categoryId != old.categoryId && widget.categoryId != null) {
      context.read<ExploreCubit>().selectCategory(widget.categoryId);
    }
    if (widget.focusSearch && !old.focusSearch) _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    context.read<ExploreCubit>().setQuery('');
  }

  Future<void> _openFilters(CatalogState catalog) async {
    final cubit = context.read<ExploreCubit>();
    final result = await showModalBottomSheet<ExploreFilters>(
      context: context,
      useRootNavigator: true, // above the tab bar
      isScrollControlled: true,
      builder: (_) => _FiltersSheet(initial: cubit.state.filters, catalog: catalog),
    );
    if (result != null) cubit.applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final catalog = context.watch<CatalogCubit>().state;
    final explore = context.watch<ExploreCubit>().state;
    final cubit = context.read<ExploreCubit>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Text(l10n.exploreTitle, style: context.textStyles.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, value, _) => TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textInputAction: TextInputAction.search,
                        onChanged: cubit.typeQuery,
                        onSubmitted: cubit.setQuery,
                        decoration: InputDecoration(
                          hintText: l10n.exploreSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.exploreClearSearch,
                                  icon: const Icon(Icons.close),
                                  onPressed: _clearSearch,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Badge(
                    isLabelVisible: explore.filters.activeCount > 0,
                    label: Text('${explore.filters.activeCount}'),
                    child: IconButton.filledTonal(
                      tooltip: l10n.exploreFilters,
                      onPressed: catalog.isReady ? () => _openFilters(catalog) : null,
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                children: [
                  ChoiceChip(
                    label: Text(l10n.exploreAllCategories),
                    selected: explore.filters.categoryId == null,
                    onSelected: (_) => cubit.selectCategory(null),
                  ),
                  for (final c in catalog.categories) ...[
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      avatar: Icon(categoryIcon(c.icon), size: AppSizes.iconSm),
                      label: Text(c.name(lang)),
                      selected: explore.filters.categoryId == c.id,
                      onSelected: (selected) => cubit.selectCategory(selected ? c.id : null),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: _results(context, catalog, explore, lang)),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context, CatalogState catalog, ExploreState explore, String lang) {
    final l10n = context.l10n;
    final cubit = context.read<ExploreCubit>();
    switch (catalog.status) {
      case CatalogStatus.loading:
        return _Grid(itemCount: 6, builder: (_, __) => const DestinationPhotoCardSkeleton(aspectRatio: AppAspect.tile));
      case CatalogStatus.failure:
        return StatusView(
          icon: Icons.cloud_off_outlined,
          tone: StatusTone.error,
          title: l10n.destinationsErrorTitle,
          message: catalog.failure!.message(l10n),
          actionLabel: l10n.commonRetry,
          onAction: context.read<CatalogCubit>().load,
        );
      case CatalogStatus.ready:
        final results = exploreResults(catalog.destinations, explore.query, explore.filters, languageCode: lang);
        if (catalog.destinations.isEmpty) {
          return StatusView(
              icon: Icons.travel_explore, title: l10n.destinationsEmptyTitle, message: l10n.destinationsEmptyBody);
        }
        if (results.isEmpty) {
          return StatusView(
            icon: Icons.search_off,
            title: l10n.exploreNoResultsTitle,
            message: explore.query.trim().isEmpty
                ? l10n.exploreNoResultsFiltersBody
                : l10n.exploreNoResultsBody(explore.query.trim()),
            actionLabel: l10n.exploreClearAll,
            onAction: () {
              _controller.clear();
              cubit.clearAll();
            },
          );
        }
        return RefreshIndicator(
          onRefresh: context.read<CatalogCubit>().load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.lg, AppSpacing.xs, AppSpacing.xs, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.exploreResultCount(results.length),
                            style: context.textStyles.labelLarge?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ),
                      ),
                      _SortMenu(
                        value: explore.filters.sort,
                        onSelected: (sort) => cubit.applyFilters(explore.filters.copyWith(sort: sort)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) => SliverGrid.builder(
                    gridDelegate: _gridDelegate(constraints.crossAxisExtent),
                    itemCount: results.length,
                    itemBuilder: (context, i) => DestinationPhotoCard(
                      key: ValueKey(results[i].id),
                      destination: results[i],
                      aspectRatio: AppAspect.tile,
                      onTap: () => context.push(AppRoutes.destination(results[i].id)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

SliverGridDelegate _gridDelegate(double width) => SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: width >= 900 ? 4 : (width >= 600 ? 3 : 2),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: AppAspect.tile,
    );

class _Grid extends StatelessWidget {
  const _Grid({required this.itemCount, required this.builder});
  final int itemCount;
  final IndexedWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.commonLoading,
        child: LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: _gridDelegate(constraints.maxWidth - AppSpacing.lg * 2),
            itemCount: itemCount,
            itemBuilder: builder,
          ),
        ),
      );
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onSelected});
  final ExploreSort value;
  final ValueChanged<ExploreSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(ExploreSort s) => switch (s) {
          ExploreSort.featured => l10n.exploreSortFeatured,
          ExploreSort.priceLowToHigh => l10n.exploreSortPriceLow,
          ExploreSort.priceHighToLow => l10n.exploreSortPriceHigh,
          ExploreSort.name => l10n.exploreSortName,
        };
    return PopupMenuButton<ExploreSort>(
      tooltip: l10n.exploreSort,
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => [for (final s in ExploreSort.values) PopupMenuItem(value: s, child: Text(label(s)))],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: AppSizes.iconSm, color: context.colors.primary),
            const SizedBox(width: AppSpacing.xxs),
            Text(label(value), style: context.textStyles.labelLarge?.copyWith(color: context.colors.primary)),
          ],
        ),
      ),
    );
  }
}

/// Price and trip length — both backed by real package data
/// (`destination_summaries.from_price`, `min_days`, `max_days`).
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial, required this.catalog});
  final ExploreFilters initial;
  final CatalogState catalog;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late double? _maxPrice = widget.initial.maxPrice;
  late Set<TripLength> _lengths = {...widget.initial.lengths};

  /// Slider range from the catalog's real "from" prices, rounded to 50.
  (double, double)? get _priceRange {
    final prices = widget.catalog.destinations.map((d) => d.fromPrice).whereType<double>().toList();
    if (prices.isEmpty) return null;
    prices.sort();
    final low = (prices.first / 50).floorToDouble() * 50;
    final high = (prices.last / 50).ceilToDouble() * 50;
    return high > low ? (low, high) : null;
  }

  String? get _currency => widget.catalog.destinations.map((d) => d.currency).whereType<String>().toSet().singleOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final range = _priceRange;
    final currency = _currency;
    String money(double v) => currency == null ? v.round().toString() : formatPrice(v, currency, localeTag);
    String lengthLabel(TripLength l) => switch (l) {
          TripLength.short => l10n.exploreLengthShort,
          TripLength.medium => l10n.exploreLengthMedium,
          TripLength.long => l10n.exploreLengthLong,
        };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.exploreFilters, style: context.textStyles.titleLarge),
            if (range != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Text(l10n.exploreMaxPrice, style: context.textStyles.titleSmall)),
                  Text(
                    _maxPrice == null ? l10n.exploreAnyPrice : l10n.explorePriceUpTo(money(_maxPrice!)),
                    style: context.textStyles.labelLarge?.copyWith(color: context.colors.primary),
                  ),
                ],
              ),
              Slider(
                min: range.$1,
                max: range.$2,
                divisions: ((range.$2 - range.$1) / 50).round().clamp(1, 200),
                value: (_maxPrice ?? range.$2).clamp(range.$1, range.$2),
                label: money(_maxPrice ?? range.$2),
                onChanged: (v) => setState(() => _maxPrice = v >= range.$2 ? null : v),
              ),
              Text(
                l10n.explorePriceNote,
                style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.exploreTripLength, style: context.textStyles.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final l in TripLength.values)
                  FilterChip(
                    label: Text(lengthLabel(l)),
                    selected: _lengths.contains(l),
                    onSelected: (on) => setState(() => _lengths = on ? {..._lengths, l} : ({..._lengths}..remove(l))),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _maxPrice = null;
                      _lengths = {};
                    }),
                    child: Text(l10n.exploreReset),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      widget.initial.copyWith(maxPrice: () => _maxPrice, lengths: _lengths),
                    ),
                    child: Text(l10n.exploreApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
