import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../logic/favorites/favorites_cubit.dart';
import '../../common/l10n_extensions.dart';

/// Heart toggle bound to the shared [FavoritesCubit].
///
/// Disabled until favourites have loaded and while this destination's
/// request is in flight, so double taps can't race each other.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.destinationId, this.onImage = false});

  final String destinationId;

  /// Draws a solid circular backdrop so the icon stays visible over photos.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (isFavorite, isPending, isReady) = context.select(
      (FavoritesCubit c) => (
        c.state.isFavorite(destinationId),
        c.state.isPending(destinationId),
        c.state.status == FavoritesStatus.ready,
      ),
    );

    final icon = AnimatedSwitcher(
      duration: AppDurations.medium,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        key: ValueKey(isFavorite),
        color: isFavorite ? colors.error : (onImage ? colors.onSurface : colors.onSurfaceVariant),
      ),
    );

    return IconButton(
      tooltip: isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
      onPressed: isReady && !isPending ? () => context.read<FavoritesCubit>().toggle(destinationId) : null,
      style: onImage
          ? IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerLowest.withValues(alpha: 0.92),
              disabledBackgroundColor: colors.surfaceContainerLowest.withValues(alpha: 0.7),
            )
          : null,
      icon: Semantics(selected: isFavorite, child: icon),
    );
  }
}
