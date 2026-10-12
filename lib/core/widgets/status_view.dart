import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Centered illustration + message + optional action. Used for empty,
/// error and "not found" states so they look consistent everywhere.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.tone = StatusTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A way out next to [onAction] (e.g. "View my trips" beside "Retry").
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bubble, glyph) = switch (tone) {
      StatusTone.neutral => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
      StatusTone.error => (colors.errorContainer, colors.onErrorContainer),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: bubble,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: glyph),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(onPressed: onSecondaryAction, child: Text(secondaryActionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum StatusTone { neutral, error }
