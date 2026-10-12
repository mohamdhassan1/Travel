import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/catalog_models.dart';
import '../../common/l10n_extensions.dart';
import '../../favorites/widgets/favorite_button.dart';

/// Destination card used by the Browse and Favourites lists.
class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination, required this.onTap});

  final DestinationSummary destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final d = destination;

    String? duration;
    if (d.minDays != null && d.maxDays != null) {
      duration =
          d.minDays == d.maxDays ? l10n.destinationDays(d.minDays!) : l10n.destinationDaysRange(d.minDays!, d.maxDays!);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // No Hero: the Saved tab stays mounted next to the other tabs,
                  // where the same destination may also be shown.
                  AppNetworkImage(url: d.coverImage, cacheWidth: 720, errorLabel: l10n.destinationImageUnavailable),
                  if (d.isFeatured)
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: AppSpacing.sm,
                      child: Chip(
                        label: Text(l10n.destinationFeatured),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: context.colors.surfaceContainerLowest,
                      ),
                    ),
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    end: AppSpacing.xs,
                    child: FavoriteButton(destinationId: d.id, onImage: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name(lang), style: context.textStyles.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        d.country(lang),
                        style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(d.summary(lang), style: context.textStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (d.hasPackages)
                    Wrap(
                      spacing: AppSpacing.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.destinationFromPrice(formatPrice(d.fromPrice!, d.currency!, localeTag)),
                          style: context.textStyles.titleMedium?.copyWith(color: context.colors.primary),
                        ),
                        Text(l10n.destinationPerPerson, style: context.textStyles.bodySmall),
                        if (duration != null)
                          Text(
                            duration,
                            style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                      ],
                    )
                  else
                    Text(
                      l10n.destinationNoPackages,
                      style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card-shaped placeholders matching [DestinationCard].
class DestinationCardSkeletonList extends StatelessWidget {
  const DestinationCardSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final block = context.colors.surfaceContainerHigh;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: AlignmentDirectional.centerStart,
          child: Container(height: height, decoration: BoxDecoration(color: block, borderRadius: AppRadius.smAll)),
        );

    return Semantics(
      label: context.l10n.commonLoading,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: block)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bar(0.5, 20),
                    const SizedBox(height: AppSpacing.xs),
                    bar(0.3, 14),
                    const SizedBox(height: AppSpacing.sm),
                    bar(0.9, 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered, width-constrained list of [DestinationCard]s.
class DestinationCardList extends StatelessWidget {
  const DestinationCardList({super.key, required this.destinations, required this.onOpen});

  final List<DestinationSummary> destinations;
  final void Function(DestinationSummary destination) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: destinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: DestinationCard(
            key: ValueKey(destinations[i].id),
            destination: destinations[i],
            onTap: () => onOpen(destinations[i]),
          ),
        ),
      ),
    );
  }
}
