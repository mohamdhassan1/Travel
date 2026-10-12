import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/status_view.dart';
import '../../routing/app_routes.dart';
import 'l10n_extensions.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: StatusView(
        icon: Icons.explore_off_outlined,
        title: l10n.notFoundTitle,
        message: l10n.notFoundBody,
        actionLabel: l10n.commonGoHome,
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
