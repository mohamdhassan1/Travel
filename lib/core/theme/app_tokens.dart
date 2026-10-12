import 'package:flutter/material.dart';

/// 4-pt spacing scale.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal padding for screen content.
  static const EdgeInsetsDirectional screen = EdgeInsetsDirectional.symmetric(
    horizontal: lg,
  );

  /// Max width of form-like content on tablets / web.
  static const double formMaxWidth = 440;

  /// Max width of reading content on tablets / web.
  static const double contentMaxWidth = 720;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Photo cards (Home carousels, Explore grid).
  static const double card = 20;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

/// Motion curves: one family so transitions feel related.
abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
}

/// Image proportions used across the app, so photos crop consistently.
abstract final class AppAspect {
  /// Wide cards in lists.
  static const double wide = 16 / 10;

  /// Tall carousel cards on Home.
  static const double portrait = 3 / 4;

  /// Grid tiles in Explore.
  static const double tile = 4 / 5;
}

abstract final class AppSizes {
  static const double buttonHeight = 52;
  static const double minTouchTarget = 48;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;
}

/// Soft, low-contrast elevation used by cards over photos and sheets.
abstract final class AppShadows {
  static List<BoxShadow> soft(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.shadow.withValues(
            alpha: scheme.brightness == Brightness.light ? 0.08 : 0.4,
          ),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
