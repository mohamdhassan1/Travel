import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/notifications/local_reminder_notifier.dart';
import '../../logic/notifications/device_notifications_cubit.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsCubit>();
    final state = settings.state;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: l10n.settingsLanguage,
            icon: Icons.translate,
            child: _Choice<Locale?>(
              value: state.locale,
              onChanged: settings.setLocale,
              options: [
                (null, l10n.commonSystemDefault),
                (const Locale('en'), l10n.languageEnglish),
                (const Locale('ar'), l10n.languageArabic),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.settingsTheme,
            icon: Icons.dark_mode_outlined,
            child: _Choice<ThemeMode>(
              value: state.themeMode,
              onChanged: (m) => settings.setThemeMode(m ?? ThemeMode.system),
              options: [
                (ThemeMode.system, l10n.commonSystemDefault),
                (ThemeMode.light, l10n.settingsThemeLight),
                (ThemeMode.dark, l10n.settingsThemeDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.settingsSectionNotifications,
            icon: Icons.notifications_outlined,
            child: const _DeviceNotificationsSettings(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.settingsSectionAccount,
            icon: Icons.manage_accounts_outlined,
            child: ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: Text(l10n.accountChangePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.resetPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.accountSectionAbout,
            icon: Icons.info_outline,
            child: ListTile(
              title: Text(l10n.settingsPhotoCredits),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.credits),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xxs,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(clipBehavior: Clip.antiAlias, child: child),
      ],
    );
  }
}

/// Single-choice list backed by [RadioGroup].
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T?> onChanged;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: value,
      onChanged: onChanged,
      child: Column(
        children: [
          for (final (option, label) in options) RadioListTile<T>(value: option, title: Text(label)),
        ],
      ),
    );
  }
}

/// Local trip reminders on this device, and the OS permission they need.
/// Honest about scope: the switch is a device-local preference and doesn't
/// change what a server may push.
class _DeviceNotificationsSettings extends StatelessWidget {
  const _DeviceNotificationsSettings();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DeviceNotificationsCubit>();
    return BlocConsumer<DeviceNotificationsCubit, DeviceNotificationsState>(
      listenWhen: (a, b) => b.deniedSerial != a.deniedSerial,
      listener: (context, _) => context.showSnack(l10n.notificationsPermissionDeniedToast),
      builder: (context, state) {
        if (!state.remindersSupported) {
          return ListTile(
            leading: const Icon(Icons.notifications_off_outlined),
            title: Text(l10n.settingsTripReminders),
            subtitle: Text(l10n.settingsNotificationsUnsupported),
          );
        }
        final muted = context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
        // The OS permission matters for reminders and for pushes.
        final needsPermission = state.remindersEnabled || state.pushAvailable;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.alarm_outlined),
              title: Text(l10n.settingsTripReminders),
              subtitle: Text(l10n.settingsTripRemindersSubtitle),
              value: state.remindersEnabled,
              onChanged: cubit.setRemindersEnabled,
            ),
            if (needsPermission && state.permission == NotificationPermission.notDetermined)
              ListTile(
                title: Text(l10n.settingsNotificationsAllowHint, style: muted),
                trailing: TextButton(onPressed: cubit.requestPermission, child: Text(l10n.settingsNotificationsAllow)),
              ),
            if (needsPermission && state.permission == NotificationPermission.denied)
              ListTile(
                leading: Icon(Icons.block, color: context.colors.error),
                title: Text(l10n.settingsNotificationsBlocked, style: muted),
                trailing: TextButton(
                  onPressed: cubit.openSystemSettings,
                  child: Text(l10n.settingsNotificationsOpenSettings),
                ),
              ),
            const Divider(height: 1),
            // Remote pushes: a status, not a switch — the device can only
            // say whether it is registered; the server decides what is sent.
            ListTile(
              leading: Icon(
                  state.tokenRegistered ? Icons.notifications_active_outlined : Icons.notifications_paused_outlined),
              title: Text(l10n.settingsPushTitle),
              subtitle: Text(
                !state.pushAvailable
                    ? l10n.settingsPushUnavailable
                    : state.tokenRegistered
                        ? l10n.settingsPushOn
                        : state.permission == NotificationPermission.granted
                            ? l10n.settingsPushNotRegistered
                            : l10n.settingsPushNeedsPermission,
              ),
            ),
          ],
        );
      },
    );
  }
}
