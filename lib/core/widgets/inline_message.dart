import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

enum InlineMessageTone { error, info, success }

/// Compact banner for form-level feedback (e.g. "Incorrect email or
/// password"). Announced to screen readers when it appears.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.tone = InlineMessageTone.error,
    this.action,
  });

  final String message;
  final InlineMessageTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    final (background, foreground, icon) = switch (tone) {
      InlineMessageTone.error => (
          colors.errorContainer,
          colors.onErrorContainer,
          Icons.error_outline,
        ),
      InlineMessageTone.info => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
          Icons.info_outline,
        ),
      InlineMessageTone.success => (
          palette.successContainer,
          palette.onSuccessContainer,
          Icons.check_circle_outline,
        ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.mdAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: AppSizes.iconMd),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    message,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            if (action != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: foreground),
                  child: action!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
