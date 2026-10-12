import 'package:flutter/material.dart';

/// Brand palette. Every color in the app resolves from here, through
/// [ColorScheme] or [AppPalette] — widgets never hardcode hex values.
///
/// Teal (primary) reads as sea & sky; terracotta (secondary) as sand & stone.
abstract final class AppColors {
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCCF3EC),
    onPrimaryContainer: Color(0xFF03302C),
    secondary: Color(0xFFB4532A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFE3D5),
    onSecondaryContainer: Color(0xFF4A1A06),
    tertiary: Color(0xFF1F3B5C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD6E4F7),
    onTertiaryContainer: Color(0xFF0B1D33),
    error: Color(0xFFB42318),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE4E2),
    onErrorContainer: Color(0xFF7A271A),
    surface: Color(0xFFF7F9FA),
    onSurface: Color(0xFF101828),
    onSurfaceVariant: Color(0xFF566273),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F4F6),
    surfaceContainer: Color(0xFFEBEFF2),
    surfaceContainerHigh: Color(0xFFE4E9ED),
    surfaceContainerHighest: Color(0xFFDCE2E7),
    outline: Color(0xFFC4CDD5),
    outlineVariant: Color(0xFFE1E6EA),
    inverseSurface: Color(0xFF1D2939),
    onInverseSurface: Color(0xFFF2F4F7),
    inversePrimary: Color(0xFF6FDCCB),
    shadow: Color(0xFF0B1220),
    scrim: Color(0xFF000000),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6FDCCB),
    onPrimary: Color(0xFF00382F),
    primaryContainer: Color(0xFF0E5A53),
    onPrimaryContainer: Color(0xFFCCF3EC),
    secondary: Color(0xFFFFB597),
    onSecondary: Color(0xFF571E05),
    secondaryContainer: Color(0xFF773415),
    onSecondaryContainer: Color(0xFFFFE3D5),
    tertiary: Color(0xFFAFC8EA),
    onTertiary: Color(0xFF10263F),
    tertiaryContainer: Color(0xFF2A4568),
    onTertiaryContainer: Color(0xFFD6E4F7),
    error: Color(0xFFFDA29B),
    onError: Color(0xFF55160C),
    errorContainer: Color(0xFF7A271A),
    onErrorContainer: Color(0xFFFEE4E2),
    surface: Color(0xFF0D1316),
    onSurface: Color(0xFFE5ECEF),
    onSurfaceVariant: Color(0xFFA2AFB7),
    surfaceContainerLowest: Color(0xFF090E10),
    surfaceContainerLow: Color(0xFF141B1F),
    surfaceContainer: Color(0xFF182024),
    surfaceContainerHigh: Color(0xFF1F282D),
    surfaceContainerHighest: Color(0xFF293338),
    outline: Color(0xFF3F4C54),
    outlineVariant: Color(0xFF283238),
    inverseSurface: Color(0xFFE5ECEF),
    onInverseSurface: Color(0xFF1A2226),
    inversePrimary: Color(0xFF0F766E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

/// Semantic colors Material's [ColorScheme] doesn't cover (status chips,
/// success feedback). Access with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.imageScrim,
  });

  static const light = AppPalette(
    success: Color(0xFF067647),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCFAE6),
    onSuccessContainer: Color(0xFF054F31),
    warning: Color(0xFFB54708),
    warningContainer: Color(0xFFFEF0C7),
    onWarningContainer: Color(0xFF7A2E0E),
    imageScrim: Color(0xB3000000),
  );

  static const dark = AppPalette(
    success: Color(0xFF75E0A7),
    onSuccess: Color(0xFF053321),
    successContainer: Color(0xFF085D3A),
    onSuccessContainer: Color(0xFFDCFAE6),
    warning: Color(0xFFFEC84B),
    warningContainer: Color(0xFF7A2E0E),
    onWarningContainer: Color(0xFFFEF0C7),
    imageScrim: Color(0xCC000000),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Bottom gradient over photos so white text stays readable.
  final Color imageScrim;

  @override
  AppPalette copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? imageScrim,
  }) =>
      AppPalette(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        warning: warning ?? this.warning,
        warningContainer: warningContainer ?? this.warningContainer,
        onWarningContainer: onWarningContainer ?? this.onWarningContainer,
        imageScrim: imageScrim ?? this.imageScrim,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
    );
  }
}
