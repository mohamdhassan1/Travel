import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../logic/favorites/favorites_cubit.dart';
import '../../common/l10n_extensions.dart';

/// App-wide snack bars for favourite toggles. Success is only announced after
/// the server confirmed it; failures say what went wrong (the heart has
/// already been rolled back by then).
class FavoriteFeedbackListener extends StatelessWidget {
  const FavoriteFeedbackListener({super.key, required this.messengerKey, required this.child});

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Signing out (or switching accounts) resets favourites; any snack bar
    // about the previous account — e.g. an "Undo" — must not outlive it.
    final clearOnReset = BlocListener<FavoritesCubit, FavoritesState>(
      listenWhen: (previous, current) =>
          previous.status != FavoritesStatus.signedOut && current.status == FavoritesStatus.signedOut,
      listener: (_, __) => messengerKey.currentState?.hideCurrentSnackBar(),
      child: child,
    );

    return BlocListener<FavoritesCubit, FavoritesState>(
      listenWhen: (previous, current) => current.lastEvent != null && previous.lastEvent != current.lastEvent,
      listener: (context, state) {
        final event = state.lastEvent!;
        final messenger = messengerKey.currentState;
        if (messenger == null) return;
        final l10n = AppLocalizations.of(context);
        final reason = event.failure?.message(l10n) ?? '';
        final text = switch (event.change) {
          FavoriteChange.added => l10n.favoriteAdded,
          FavoriteChange.removed => l10n.favoriteRemoved,
          FavoriteChange.addFailed => l10n.favoriteAddFailed(reason),
          FavoriteChange.removeFailed => l10n.favoriteRemoveFailed(reason),
        };
        final cubit = context.read<FavoritesCubit>();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(text),
            duration: Duration(seconds: event.failed ? 5 : 3),
            action: event.change == FavoriteChange.removed
                ? SnackBarAction(label: l10n.commonUndo, onPressed: () => cubit.toggle(event.destinationId))
                : null,
          ));
      },
      child: clearOnReset,
    );
  }
}
