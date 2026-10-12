import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local UI preferences. Nothing sensitive is stored here.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'settings.theme_mode';
  static const _localeKey = 'settings.locale';
  static const _onboardingKey = 'onboarding.completed';
  static const _tripRemindersKey = 'notifications.trip_reminders';
  static const _permissionRequestedKey = 'notifications.permission_requested';

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_themeModeKey),
        orElse: () => ThemeMode.system,
      );

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeModeKey, mode.name);

  /// `null` means "follow the device language".
  Locale? get locale {
    final code = _prefs.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) =>
      locale == null ? _prefs.remove(_localeKey) : _prefs.setString(_localeKey, locale.languageCode);

  bool get onboardingCompleted => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingCompleted() => _prefs.setBool(_onboardingKey, true);

  /// Local trip reminders on this device (default on). Doesn't affect push
  /// notifications sent by a server.
  bool get tripRemindersEnabled => _prefs.getBool(_tripRemindersKey) ?? true;

  Future<void> setTripRemindersEnabled(bool enabled) => _prefs.setBool(_tripRemindersKey, enabled);

  /// Whether the app already showed the OS notification prompt, so it isn't
  /// shown again unprompted.
  bool get notificationPermissionRequested => _prefs.getBool(_permissionRequestedKey) ?? false;

  Future<void> setNotificationPermissionRequested() => _prefs.setBool(_permissionRequestedKey, true);
}
