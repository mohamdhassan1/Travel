import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/status_view.dart';
import '../../data/media/share_service.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../logic/catalog/destination_details_cubit.dart';
import '../../logic/catalog/recently_viewed_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import '../favorites/widgets/favorite_button.dart';
import 'widgets/photo_viewer.dart';
import 'widgets/weather_section.dart';

/// Details of one destination, loaded by [destinationId] from the route.
class DestinationDetailsScreen extends StatelessWidget {
  const DestinationDetailsScreen({super.key, required this.destinationId});

  final String destinationId;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => DestinationDetailsCubit(context.read<CatalogRepository>(), destinationId)..load(),
        child: const _DetailsView(),
      );
}

class _DetailsView extends StatelessWidget {
  const _DetailsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destination = context.select((DestinationDetailsCubit c) => c.state.destination);

    final page = switch (destination.status) {
      LoadStatus.loading || LoadStatus.empty => const _LoadingDetails(),
      LoadStatus.failure => Scaffold(
          appBar: AppBar(),
          body: destination.failure!.type == FailureType.notFound
              ? StatusView(
                  icon: Icons.explore_off_outlined,
                  title: l10n.detailsNotFoundTitle,
                  message: l10n.detailsNotFoundBody,
                  actionLabel: l10n.detailsBackToDestinations,
                  onAction: () => context.canPop() ? context.pop() : context.go(AppRoutes.destinations),
                )
              : StatusView(
                  icon: Icons.cloud_off_outlined,
                  tone: StatusTone.error,
                  title: l10n.detailsErrorTitle,
                  message: destination.failure!.message(l10n),
                  actionLabel: l10n.commonRetry,
                  onAction: context.read<DestinationDetailsCubit>().load,
                ),
        ),
      LoadStatus.success => _DetailsContent(destination: destination.data!),
    };
    // Remember the visit (device-local, per account) once it really loaded.
    return BlocListener<DestinationDetailsCubit, DestinationDetailsState>(
      listenWhen: (a, b) => a.destination.status != LoadStatus.success && b.destination.status == LoadStatus.success,
      listener: (context, state) => context.read<RecentlyViewedCubit>().record(state.destination.data!.id),
      child: page,
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.destination});

  final DestinationDetails destination;

  static const _expandedHeight = 320.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final d = destination;
    final colors = context.colors;
    final bestSeason = d.bestSeason(lang);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                style: IconButton.styleFrom(backgroundColor: colors.surfaceContainerLowest.withValues(alpha: 0.92)),
                onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.destinations),
                icon: const BackButtonIcon(),
              ),
            ),
            actions: [
              _ShareButton(destination: d),
              FavoriteButton(destinationId: d.id, onImage: true),
              const SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: _CollapsingHeader(
              expandedHeight: _expandedHeight,
              title: d.name(lang),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: d.coverImage, errorLabel: l10n.destinationImageUnavailable),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.3, 1],
                        colors: [
                          context.palette.imageScrim.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name(lang), style: context.textStyles.headlineMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            d.country(lang),
                            style: context.textStyles.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (bestSeason != null)
                            _InfoPill(icon: Icons.wb_sunny_outlined, label: l10n.detailsBestSeason, value: bestSeason),
                          _InfoPill(
                            icon: Icons.my_location_outlined,
                            label: l10n.detailsCoordinates,
                            value: '${d.latitude.toStringAsFixed(4)}, ${d.longitude.toStringAsFixed(4)}',
                            valueDirection: ui.TextDirection.ltr,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(l10n.weatherTitle),
                      WeatherSection(latitude: d.latitude, longitude: d.longitude),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(l10n.detailsAbout),
                      Text(d.description(lang), style: context.textStyles.bodyLarge),
                      if (d.gallery.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _SectionTitle(l10n.detailsGallery),
                        _Gallery(urls: d.gallery),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(l10n.detailsPackagesTitle),
                      Text(
                        l10n.detailsPriceNote,
                        style: context.textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _PackagesSection(),
                      if (d.imageCredit != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.detailsPhotoCredit(d.imageCredit!),
                          style: context.textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo background that fades into a plain app bar showing [title] once
/// the header is collapsed.
class _CollapsingHeader extends StatelessWidget {
  const _CollapsingHeader({required this.expandedHeight, required this.title, required this.background});

  final double expandedHeight;
  final String title;
  final Widget background;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = kToolbarHeight + topPadding;
        final maxHeight = expandedHeight + topPadding;
        final t = ((constraints.maxHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
        final collapsed = t < 0.15;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: t, child: background),
            PositionedDirectional(
              start: 72,
              end: 72,
              bottom: 0,
              height: kToolbarHeight,
              child: AnimatedOpacity(
                opacity: collapsed ? 1 : 0,
                duration: AppDurations.fast,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child:
                      Text(title, style: context.textStyles.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Semantics(header: true, child: Text(text, style: context.textStyles.titleLarge)),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.value, this.valueDirection});

  final IconData icon;
  final String label;
  final String value;
  final ui.TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: AppRadius.mdAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: context.textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
              Text(value, style: context.textStyles.labelLarge, textDirection: valueDirection),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => Semantics(
          image: true,
          button: true,
          label: l10n.detailsGalleryPhoto(i + 1, urls.length),
          child: ClipRRect(
            borderRadius: AppRadius.lgAll,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: urls[i], cacheWidth: 300, errorLabel: l10n.destinationImageUnavailable),
                  // Opens the photo full screen (swipe + zoom).
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(onTap: () => showPhotoViewer(context, urls, i)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PackagesSection extends StatelessWidget {
  const _PackagesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final packages = context.select((DestinationDetailsCubit c) => c.state.packages);
    return switch (packages.status) {
      LoadStatus.loading => const _PackageSkeleton(),
      LoadStatus.empty => InlineMessage(message: l10n.detailsPackagesEmpty, tone: InlineMessageTone.info),
      LoadStatus.failure => InlineMessage(
          message: '${l10n.detailsPackagesError} ${packages.failure!.message(l10n)}',
          action: TextButton(
            onPressed: context.read<DestinationDetailsCubit>().loadPackages,
            child: Text(l10n.commonRetry),
          ),
        ),
      LoadStatus.success => Column(
          children: [
            for (final p in packages.data!) ...[
              PackageCard(package: p),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
    };
  }
}

/// One package with only the fields the schema actually provides.
class PackageCard extends StatelessWidget {
  const PackageCard({super.key, required this.package});

  final TravelPackage package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final colors = context.colors;
    final p = package;
    final includes = p.includes(lang);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(p.name(lang), style: context.textStyles.titleMedium)),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(p.pricePerPerson, p.currency, locale.toLanguageTag()),
                      style: context.textStyles.titleLarge?.copyWith(color: colors.primary),
                    ),
                    Text(
                      l10n.destinationPerPerson,
                      style: context.textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [
                _Meta(icon: Icons.schedule_outlined, text: l10n.destinationDays(p.durationDays)),
                _Meta(icon: Icons.group_outlined, text: l10n.packageMaxTravelers(p.maxTravelers)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(p.description(lang), style: context.textStyles.bodyMedium),
            if (includes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.packageIncludes, style: context.textStyles.labelLarge),
              const SizedBox(height: AppSpacing.xxs),
              for (final item in includes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: AppSizes.iconSm, color: context.palette.success),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(item, style: context.textStyles.bodyMedium)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.packageBookCta,
              icon: Icons.event_available_outlined,
              onPressed: () => context.push(AppRoutes.book(p.destinationId, packageId: p.id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xxs),
          Text(text, style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      );
}

class _PackageSkeleton extends StatelessWidget {
  const _PackageSkeleton();

  @override
  Widget build(BuildContext context) {
    final block = context.colors.surfaceContainerHigh;
    return Semantics(
      label: context.l10n.commonLoading,
      child: Column(
        children: [
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(height: 120, decoration: BoxDecoration(color: block, borderRadius: AppRadius.lgAll)),
            ),
        ],
      ),
    );
  }
}

class _LoadingDetails extends StatelessWidget {
  const _LoadingDetails();

  @override
  Widget build(BuildContext context) {
    final block = context.colors.surfaceContainerHigh;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: block, borderRadius: AppRadius.smAll),
        );
    return Scaffold(
      appBar: AppBar(),
      body: Semantics(
        label: context.l10n.commonLoading,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: DecoratedBox(decoration: BoxDecoration(color: block, borderRadius: AppRadius.lgAll)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(alignment: AlignmentDirectional.centerStart, child: bar(180, 28)),
            const SizedBox(height: AppSpacing.xs),
            Align(alignment: AlignmentDirectional.centerStart, child: bar(110, 16)),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < 4; i++) ...[bar(double.infinity, 14), const SizedBox(height: AppSpacing.xs)],
          ],
        ),
      ),
    );
  }
}

/// Shares the destination's name, summary and in-app link.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.destination});
  final DestinationDetails destination;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final d = destination;
    return IconButton(
      tooltip: l10n.detailsShare,
      style: IconButton.styleFrom(backgroundColor: context.colors.surfaceContainerLowest.withValues(alpha: 0.92)),
      icon: const Icon(Icons.ios_share),
      onPressed: () async {
        final box = context.findRenderObject() as RenderBox?;
        final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
        final shared = await context.read<ShareService>().shareText(
              l10n.detailsShareText(
                  d.name(lang), d.country(lang), d.summary(lang), 'rahala://rahala.app${AppRoutes.destination(d.id)}'),
              subject: d.name(lang),
              origin: origin,
            );
        if (!shared && context.mounted) context.showSnack(l10n.detailsShareUnavailable);
      },
    );
  }
}
