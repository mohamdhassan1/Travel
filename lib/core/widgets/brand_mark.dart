import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The Rahala logo mark: a compass-like "travel explore" glyph in a rounded
/// square. Drawn in code so it scales crisply and follows the theme.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.inverted = false});

  final double size;

  /// Light mark on a dark/brand background (splash, photos).
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = inverted ? scheme.onPrimary : scheme.primary;
    final foreground = inverted ? scheme.primary : scheme.onPrimary;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(
          Icons.travel_explore_rounded,
          color: foreground,
          size: size * 0.56,
        ),
      ),
    );
  }
}

/// Mark + wordmark lockup.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.name, this.inverted = false});

  final String name;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: 36, inverted: inverted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: inverted ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
      ],
    );
  }
}
