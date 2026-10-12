import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/app_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.onboardingCompleted = false,
  });

  final ThemeMode themeMode;

  /// `null` follows the device language.
  final Locale? locale;
  final bool onboardingCompleted;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? Function()? locale,
    bool? onboardingCompleted,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale != null ? locale() : this.locale,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );

  @override
  List<Object?> get props => [themeMode, locale, onboardingCompleted];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs)
      : super(
          SettingsState(
            themeMode: _prefs.themeMode,
            locale: _prefs.locale,
            onboardingCompleted: _prefs.onboardingCompleted,
          ),
        );

  static const supportedLanguageCodes = ['en', 'ar'];

  final AppPreferences _prefs;

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setThemeMode(mode);
  }

  Future<void> setLocale(Locale? locale) async {
    assert(
      locale == null || supportedLanguageCodes.contains(locale.languageCode),
    );
    emit(state.copyWith(locale: () => locale));
    await _prefs.setLocale(locale);
  }

  Future<void> completeOnboarding() async {
    if (state.onboardingCompleted) return;
    emit(state.copyWith(onboardingCompleted: true));
    await _prefs.setOnboardingCompleted();
  }
}
