import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppButtonVariant { filled, outlined, text }

/// Full-width primary action with an inline loading state. While [loading],
/// the button is disabled and announces progress to screen readers.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spinnerColor = variant == AppButtonVariant.filled ? scheme.onPrimary : scheme.primary;

    final child = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: loading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: spinnerColor,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSizes.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final onTap = loading ? null : onPressed;
    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(onPressed: onTap, child: child),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: onTap,
          child: child,
        ),
      AppButtonVariant.text => TextButton(onPressed: onTap, child: child),
    };

    return Semantics(
      button: true,
      label: loading ? label : null,
      liveRegion: loading,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
