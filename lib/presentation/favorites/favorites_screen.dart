import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/status_view.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../logic/common/load_state.dart';
import '../../logic/favorites/favorite_destinations_cubit.dart';
import '../../logic/favorites/favorites_cubit.dart';
import '../../routing/app_routes.dart';
import '../catalog/widgets/destination_card.dart';
import '../common/l10n_extensions.dart';

/// The signed-in user's saved destinations, read from Supabase.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) =>
            FavoriteDestinationsCubit(context.read<CatalogRepository>(), context.read<FavoritesCubit>()),
        child: const _FavoritesView(),
      );
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  /// Re-reads saved ids (e.g. saved on another device); a failure keeps the
  /// list and says so.
  Future<void> _refresh(BuildContext context) async {
    final favorites = context.read<FavoritesCubit>();
    final l10n = context.l10n;
    await favorites.refresh();
    final failure = favorites.state.failure;
    if (failure != null && context.mounted) context.showSnack(l10n.favoritesRefreshFailed(failure.message(l10n)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: BlocBuilder<FavoriteDestinationsCubit, LoadState<List<DestinationSummary>>>(
        builder: (context, state) => switch (state.status) {
          LoadStatus.loading => const DestinationCardSkeletonList(count: 2),
          LoadStatus.failure => StatusView(
              icon: Icons.cloud_off_outlined,
              tone: StatusTone.error,
              title: l10n.favoritesErrorTitle,
              message: state.failure!.message(l10n),
              actionLabel: l10n.commonRetry,
              onAction: context.read<FavoriteDestinationsCubit>().retry,
            ),
          LoadStatus.empty => StatusView(
              icon: Icons.favorite_border,
              title: l10n.favoritesEmptyTitle,
              message: l10n.favoritesEmptyBody,
              actionLabel: l10n.accountBrowseDestinations,
              onAction: () => context.go(AppRoutes.explore),
            ),
          LoadStatus.success => RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: DestinationCardList(
                destinations: state.data!,
                onOpen: (d) => context.push(AppRoutes.destination(d.id)),
              ),
            ),
        },
      ),
    );
  }
}
