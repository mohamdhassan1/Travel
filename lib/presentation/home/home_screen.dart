import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/booking.dart';
import '../../data/models/catalog_models.dart';
import '../../logic/auth/session_cubit.dart';
import '../../logic/booking/my_bookings_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/catalog/recently_viewed_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../logic/favorites/favorites_cubit.dart';
import '../../logic/notifications/notifications_cubit.dart';
import '../../logic/profile/profile_cubit.dart';
import '../../routing/app_routes.dart';
import '../booking/widgets/booking_widgets.dart' show formatShortDate;
import '../catalog/widgets/catalog_visuals.dart';
import '../common/l10n_extensions.dart';
import '../profile/widgets/user_avatar.dart';

/// Signed-in landing page. Every section shows real data: the catalog from
/// Supabase, the user's own next booking, favourites, notifications and
/// recently viewed destinations (device-local). Nothing is ranked by
/// invented popularity — "Featured" is the catalog's own curated flag.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<CatalogCubit>().load(),
      context.read<MyBookingsCubit>().load(),
      context.read<NotificationsCubit>().refresh(),
      context.read<ProfileCubit>().load(),
    ]);
  }

  void _openDestination(BuildContext context, DestinationSummary d) => context.push(AppRoutes.destination(d.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  const SliverToBoxAdapter(child: _SearchEntry()),
                  const SliverToBoxAdapter(child: _NextTrip()),
                  SliverToBoxAdapter(child: _CatalogSections(onOpen: (d) => _openDestination(context, d))),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileName = context.select((ProfileCubit c) => c.state.profile?.fullName.trim());
    final sessionName = context.select((SessionCubit c) => c.state.user?.fullName?.trim());
    final name = (profileName?.isNotEmpty ?? false) ? profileName! : sessionName ?? '';
    final firstName = name.split(RegExp(r'\s+')).firstOrNull ?? '';
    final unread = context.select(
      (NotificationsCubit c) => c.state.status == NotificationsStatus.ready ? c.state.unreadCount : 0,
    );
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.homeGreetingMorning
        : hour < 18
            ? l10n.homeGreetingAfternoon
            : l10n.homeGreetingEvening;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? greeting : l10n.homeGreetingName(greeting, firstName),
                  style: context.textStyles.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.homeHeadline, style: context.textStyles.headlineSmall),
              ],
            ),
          ),
          IconButton(
            tooltip: unread > 0 ? l10n.homeNotificationsUnread(unread) : l10n.notificationsTitle,
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Semantics(
            button: true,
            label: l10n.navProfile,
            child: InkResponse(
              onTap: () => context.go(AppRoutes.account),
              radius: 28,
              child: const Padding(padding: EdgeInsets.all(AppSpacing.xxs), child: UserAvatar()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Pressable(
        onTap: () => context.go(AppRoutes.exploreWith(search: true)),
        semanticLabel: l10n.homeSearchHint,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.theme.cardTheme.color,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: context.colors.outlineVariant),
            boxShadow: AppShadows.soft(context.colors),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    l10n.homeSearchHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
              ),
              Icon(Icons.tune, color: context.colors.onSurfaceVariant, size: AppSizes.iconMd),
            ],
          ),
        ),
      ),
    );
  }
}

/// The user's soonest upcoming confirmed booking, with a countdown.
class _NextTrip extends StatelessWidget {
  const _NextTrip();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<MyBookingsCubit>().state;
    final today = serverToday();

    final Widget child;
    switch (state.status) {
      case LoadStatus.loading:
        child = const SkeletonBox(height: 132, radius: AppRadius.cardAll);
      case LoadStatus.failure:
        child = InlineMessage(
          message: l10n.homeTripsError,
          action: TextButton(onPressed: context.read<MyBookingsCubit>().load, child: Text(l10n.commonRetry)),
        );
      case LoadStatus.empty:
      case LoadStatus.success:
        final next = (state.data ?? const <Booking>[]).where((b) => b.isUpcoming(today)).toList()
          ..sort((a, b) => a.travelDate.compareTo(b.travelDate));
        child = next.isEmpty ? const _NoTripCard() : _TripCard(booking: next.first, today: today);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.homeNextTrip,
          actionLabel: l10n.homeSeeAllTrips,
          onAction: () => context.go(AppRoutes.bookings),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedSwitcher(
              duration: AppDurations.medium, child: KeyedSubtree(key: ValueKey(state.status), child: child)),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking, required this.today});

  final Booking booking;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final days = booking.travelDate.difference(today).inDays;
    final countdown = days <= 0
        ? l10n.homeTripToday
        : days == 1
            ? l10n.homeTripTomorrow
            : l10n.homeTripInDays(days);
    final cover = booking.destination?.coverImage;

    return Pressable(
      onTap: () => context.push(AppRoutes.booking(booking.id)),
      semanticLabel: '${booking.destination?.name(lang) ?? booking.reference}, $countdown',
      child: Card(
        clipBehavior: Clip.antiAlias,
        // At least 132 tall; grows with large text instead of overflowing.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 112,
                  child: cover == null
                      ? ColoredBox(color: context.colors.primaryContainer, child: const Icon(Icons.luggage_outlined))
                      : AppNetworkImage(url: cover, cacheWidth: 240),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.secondaryContainer,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              countdown,
                              style:
                                  context.textStyles.labelMedium?.copyWith(color: context.colors.onSecondaryContainer),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            booking.destination?.name(lang) ?? booking.reference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatShortDate(context, booking.travelDate)} · ${l10n.bookingTravelersCount(booking.travelers)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                          if (booking.package != null)
                            Text(
                              booking.package!.name(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoTripCard extends StatelessWidget {
  const _NoTripCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: AppRadius.mdAll),
              child: Icon(Icons.flight_takeoff, color: context.colors.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeNoTripTitle, style: context.textStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeNoTripBody,
                    style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () => context.go(AppRoutes.explore), child: Text(l10n.homeNoTripCta)),
          ],
        ),
      ),
    );
  }
}

class _CatalogSections extends StatelessWidget {
  const _CatalogSections({required this.onOpen});

  final void Function(DestinationSummary) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = context.watch<CatalogCubit>().state;
    final recentIds = context.watch<RecentlyViewedCubit>().state;
    final savedCount = context.select(
      (FavoritesCubit c) => c.state.status == FavoritesStatus.ready ? c.state.ids.length : 0,
    );

    if (catalog.status == CatalogStatus.failure) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
        child: InlineMessage(
          message: '${l10n.homeCatalogError} ${catalog.failure!.message(l10n)}',
          action: TextButton(onPressed: context.read<CatalogCubit>().load, child: Text(l10n.commonRetry)),
        ),
      );
    }
    final loading = catalog.status == CatalogStatus.loading;
    final featured = catalog.featured;
    final recent = recentIds.map(catalog.destination).whereType<DestinationSummary>().toList();
    final more = [
      for (final d in catalog.destinations)
        if (!d.isFeatured) d
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeCategories),
        SizedBox(
          height: 96,
          child: loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, __) => const SizedBox(
                    width: 76,
                    child: Column(children: [SkeletonBox(width: 60, height: 60, radius: AppRadius.lgAll)]),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: catalog.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final c = catalog.categories[i];
                    return CategoryTile(category: c, onTap: () => context.go(AppRoutes.exploreWith(category: c.id)));
                  },
                ),
        ),
        SectionHeader(
          title: l10n.homeFeatured,
          subtitle: l10n.homeFeaturedSubtitle,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.go(AppRoutes.explore),
        ),
        _Carousel(destinations: featured, loading: loading, onOpen: onOpen, showFeaturedBadge: false),
        if (recent.isNotEmpty) ...[
          SectionHeader(title: l10n.homeRecentlyViewed),
          _Carousel(destinations: recent, loading: false, onOpen: onOpen, compact: true),
        ],
        if (savedCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.favorite, color: context.colors.error),
                title: Text(l10n.homeSavedShortcut(savedCount)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.favorites),
              ),
            ),
          ),
        if (more.isNotEmpty || loading) ...[
          SectionHeader(title: l10n.homeMoreToExplore, subtitle: l10n.homeMoreToExploreSubtitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 640 ? 2 : 1;
                final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
                final items = loading ? List<DestinationSummary?>.filled(2, null) : more;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final d in items)
                      SizedBox(
                        width: width,
                        child: d == null
                            ? const DestinationPhotoCardSkeleton(aspectRatio: AppAspect.wide)
                            : DestinationPhotoCard(
                                destination: d,
                                aspectRatio: AppAspect.wide,
                                showSummary: true,
                                onTap: () => onOpen(d),
                              ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.destinations,
    required this.loading,
    required this.onOpen,
    this.compact = false,
    this.showFeaturedBadge = true,
  });

  final List<DestinationSummary> destinations;
  final bool loading;
  final bool compact;
  final bool showFeaturedBadge;
  final void Function(DestinationSummary) onOpen;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 160.0 : 220.0;
    return SizedBox(
      height: width / AppAspect.portrait,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: loading ? 3 : destinations.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => SizedBox(
          width: width,
          child: loading
              ? const DestinationPhotoCardSkeleton()
              : DestinationPhotoCard(
                  key: ValueKey(destinations[i].id),
                  destination: destinations[i],
                  showFeaturedBadge: showFeaturedBadge,
                  onTap: () => onOpen(destinations[i]),
                ),
        ),
      ),
    );
  }
}
