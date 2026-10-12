import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models/catalog_models.dart';
import '../../common/l10n_extensions.dart';
import '../../favorites/widgets/favorite_button.dart';

/// Icon for a category's `icon` key in the database (unknown → generic).
IconData categoryIcon(String key) => switch (key) {
      'heritage' => Icons.account_balance_outlined,
      'city' => Icons.location_city_outlined,
      'beach' => Icons.beach_access_outlined,
      'islands' => Icons.sailing_outlined,
      _ => Icons.travel_explore,
    };

/// Round icon + label, for the Home category row.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final TravelCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Pressable(
      onTap: onTap,
      semanticLabel: category.name(lang),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: AppRadius.lgAll),
              child: Icon(categoryIcon(category.icon), color: context.colors.onPrimaryContainer, size: AppSizes.iconLg),
            ),
            const SizedBox(height: AppSpacing.xs),
            ExcludeSemantics(
              child: Text(
                category.name(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textStyles.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo-led destination card: full-bleed image, scrim, name/country and the
/// real "from" price (only if the destination has packages).
class DestinationPhotoCard extends StatelessWidget {
  const DestinationPhotoCard({
    super.key,
    required this.destination,
    required this.onTap,
    this.aspectRatio = AppAspect.portrait,
    this.showSummary = false,
    this.showFeaturedBadge = true,
  });

  final DestinationSummary destination;
  final VoidCallback onTap;
  final double aspectRatio;
  final bool showSummary;

  /// Off inside a section that is itself "Featured".
  final bool showFeaturedBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final d = destination;
    const onPhoto = Colors.white;
    final scrim = context.palette.imageScrim;

    return Pressable(
      onTap: onTap,
      semanticLabel: '${d.name(lang)}, ${d.country(lang)}',
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: AppRadius.cardAll, boxShadow: AppShadows.soft(context.colors)),
          child: ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // No Hero here: tabs stay mounted side by side and the same
                // destination can appear in several sections, so tags would clash.
                AppNetworkImage(url: d.coverImage, cacheWidth: 480, errorLabel: l10n.destinationImageUnavailable),
                // Bottom scrim keeps white text readable on any photo.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1],
                      colors: [scrim.withValues(alpha: 0), scrim],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: AppSpacing.xs,
                  end: AppSpacing.xs,
                  child: FavoriteButton(destinationId: d.id, onImage: true),
                ),
                if (d.isFeatured && showFeaturedBadge)
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: AppSpacing.sm,
                    child: _Badge(label: l10n.destinationFeatured),
                  ),
                PositionedDirectional(
                  start: AppSpacing.md,
                  end: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          d.name(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.titleLarge?.copyWith(color: onPhoto),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: onPhoto),
                            const SizedBox(width: AppSpacing.xxs),
                            Flexible(
                              child: Text(
                                d.country(lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textStyles.bodySmall?.copyWith(color: onPhoto.withValues(alpha: 0.9)),
                              ),
                            ),
                          ],
                        ),
                        if (showSummary) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            d.summary(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall?.copyWith(color: onPhoto.withValues(alpha: 0.9)),
                          ),
                        ],
                        if (d.hasPackages) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.destinationFromPrice(formatPrice(d.fromPrice!, d.currency!, localeTag)),
                            style: context.textStyles.labelLarge?.copyWith(color: onPhoto),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest.withValues(alpha: 0.92),
          borderRadius: AppRadius.smAll,
        ),
        child: Text(label, style: context.textStyles.labelSmall?.copyWith(color: context.colors.onSurface)),
      );
}

/// Placeholder matching [DestinationPhotoCard].
class DestinationPhotoCardSkeleton extends StatelessWidget {
  const DestinationPhotoCardSkeleton({super.key, this.aspectRatio = AppAspect.portrait});
  final double aspectRatio;

  @override
  Widget build(BuildContext context) =>
      AspectRatio(aspectRatio: aspectRatio, child: const SkeletonBox(radius: AppRadius.cardAll));
}
