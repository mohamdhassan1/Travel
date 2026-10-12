import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand_mark.dart';
import '../common/l10n_extensions.dart';

/// Brand screen shown while the session is being resolved (and while an
/// auth deep link is exchanged). Routing moves on as soon as state is known —
/// there is no artificial delay.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 80, inverted: true),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.appName,
              style: context.textStyles.headlineMedium?.copyWith(
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.onPrimary.withValues(alpha: 0.8),
                semanticsLabel: context.l10n.commonLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
