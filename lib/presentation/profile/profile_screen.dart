import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/auth_repository.dart' show SignOutOutcome;
import '../../data/repositories/recently_viewed_store.dart';
import '../../logic/auth/session_cubit.dart';
import '../../logic/booking/my_bookings_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../logic/notifications/notifications_cubit.dart';
import '../../logic/profile/profile_cubit.dart';
import '../../logic/profile/travel_stats.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/profile_photo_actions.dart';
import 'widgets/user_avatar.dart';

/// The Profile tab: who you are (from `profiles`), your travel record (from
/// your own bookings), and account actions.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().refreshAvatarUrlIfStale();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          context.read<ProfileCubit>().load(),
          context.read<MyBookingsCubit>().load(),
        ]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Identity(),
                    SizedBox(height: AppSpacing.lg),
                    _TravelRecord(),
                    SizedBox(height: AppSpacing.lg),
                    _Menu(),
                    SizedBox(height: AppSpacing.xl),
                    _SignOutButton(),
                    SizedBox(height: AppSpacing.xs),
                    _DeleteAccountButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select((SessionCubit c) => c.state.user);
    final state = context.watch<ProfileCubit>().state;
    if (user == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = state.profile?.fullName.trim();
    final shownName = (name != null && name.isNotEmpty) ? name : user.displayName;
    final joined = state.profile?.createdAt ?? user.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedOpacity(
                      opacity: state.photoBusy ? 0.5 : 1,
                      duration: AppDurations.medium,
                      child: const UserAvatar(radius: 48),
                    ),
                    if (state.photoBusy)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator(strokeWidth: 3))),
                    PositionedDirectional(
                      end: -4,
                      bottom: -4,
                      child: IconButton.filled(
                        tooltip: l10n.profilePhotoChange,
                        onPressed: state.isReady && !state.photoBusy ? () => showProfilePhotoActions(context) : null,
                        icon: const Icon(Icons.photo_camera_outlined, size: AppSizes.iconSm),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  shownName,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  user.email,
                  textDirection: ui.TextDirection.ltr,
                  style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                if (state.profile?.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    state.profile!.phone!,
                    textDirection: ui.TextDirection.ltr,
                    style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    _Pill(
                      icon: user.emailConfirmed ? Icons.verified_outlined : Icons.error_outline,
                      label: user.emailConfirmed ? l10n.accountEmailVerified : l10n.accountEmailNotVerified,
                      background:
                          user.emailConfirmed ? context.palette.successContainer : context.palette.warningContainer,
                      foreground:
                          user.emailConfirmed ? context.palette.onSuccessContainer : context.palette.onWarningContainer,
                    ),
                    if (joined != null)
                      _Pill(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.accountMemberSince(DateFormat.yMMMM(locale).format(joined.toLocal())),
                        background: context.colors.surfaceContainerHigh,
                        foreground: context.colors.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (state.status == LoadStatus.failure || state.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: InlineMessage(
              message: '${l10n.profileLoadError} ${state.failure!.message(l10n)}',
              action: TextButton(onPressed: context.read<ProfileCubit>().load, child: Text(l10n.commonRetry)),
            ),
          ),
      ],
    );
  }
}

/// Traveller level + statistics, computed only from the user's bookings.
class _TravelRecord extends StatelessWidget {
  const _TravelRecord();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bookings = context.watch<MyBookingsCubit>().state;
    switch (bookings.status) {
      case LoadStatus.loading:
        return const SkeletonBox(height: 220, radius: AppRadius.lgAll);
      case LoadStatus.failure:
        return InlineMessage(
          message: '${l10n.profileStatsError} ${bookings.failure!.message(l10n)}',
          action: TextButton(onPressed: context.read<MyBookingsCubit>().load, child: Text(l10n.commonRetry)),
        );
      case LoadStatus.empty:
      case LoadStatus.success:
        final stats = TravelStats.from(bookings.data ?? const <Booking>[], serverToday());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LevelCard(stats: stats),
            const SizedBox(height: AppSpacing.sm),
            _StatsGrid(stats: stats),
          ],
        );
    }
  }
}

String travelerLevelName(BuildContext context, TravelerLevel level) {
  final l10n = context.l10n;
  return switch (level) {
    TravelerLevel.newTraveler => l10n.levelNewTraveler,
    TravelerLevel.explorer => l10n.levelExplorer,
    TravelerLevel.voyager => l10n.levelVoyager,
    TravelerLevel.globetrotter => l10n.levelGlobetrotter,
  };
}

IconData travelerLevelIcon(TravelerLevel level) => switch (level) {
      TravelerLevel.newTraveler => Icons.hiking,
      TravelerLevel.explorer => Icons.explore,
      TravelerLevel.voyager => Icons.sailing,
      TravelerLevel.globetrotter => Icons.public,
    };

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.stats});
  final TravelStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = stats.level;
    final next = level.next;
    final remaining = <String>[
      if (stats.tripsToNext > 0) l10n.levelTripsMore(stats.tripsToNext),
      if (stats.countriesToNext > 0) l10n.levelCountriesMore(stats.countriesToNext),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: context.colors.secondaryContainer, shape: BoxShape.circle),
                  child: Icon(travelerLevelIcon(level), color: context.colors.onSecondaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.levelTitle,
                          style: context.textStyles.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                      Text(travelerLevelName(context, level), style: context.textStyles.titleLarge),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.levelHowItWorks,
                  onPressed: () => _showLevelRules(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stats.progressToNext),
              duration: AppDurations.slow,
              curve: AppCurves.standard,
              builder: (context, value, _) => ClipRRect(
                borderRadius: AppRadius.smAll,
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: context.colors.surfaceContainerHigh,
                  semanticsLabel: l10n.levelProgress,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              next == null
                  ? l10n.levelTopReached
                  : l10n.levelNextHint(remaining.join(l10n.listSeparator), travelerLevelName(context, next)),
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelRules(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // above the tab bar
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: [
            Text(l10n.levelHowItWorks, style: sheetContext.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.levelRulesIntro, style: sheetContext.textStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final level in TravelerLevel.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(travelerLevelIcon(level)),
                title: Text(travelerLevelName(sheetContext, level)),
                subtitle: Text(
                  level == TravelerLevel.newTraveler
                      ? l10n.levelRuleStart
                      : level.minCountries == 0
                          ? l10n.levelTripsCount(level.minTrips)
                          : l10n.levelRule(
                              l10n.levelTripsCount(level.minTrips), l10n.levelCountriesCount(level.minCountries)),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.levelRulesNote,
              style: sheetContext.textStyles.bodySmall?.copyWith(color: sheetContext.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final TravelStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.check_circle_outline, stats.completedTrips, l10n.statsCompleted),
      (Icons.event_outlined, stats.upcomingTrips, l10n.statsUpcoming),
      (Icons.place_outlined, stats.destinationsVisited, l10n.statsDestinations),
      (Icons.public, stats.countriesVisited, l10n.statsCountries),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 4 : 2;
            final width = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (icon, value, label) in items)
                  SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Semantics(
                          label: '$label: $value',
                          excludeSemantics: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, size: AppSizes.iconMd, color: context.colors.primary),
                              const SizedBox(height: AppSpacing.xs),
                              Text('$value', style: context.textStyles.headlineSmall),
                              Text(
                                label,
                                maxLines: 2,
                                style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          stats.totalBookings == 0
              ? l10n.statsNoBookings
              : l10n.statsFootnote(stats.totalBookings, stats.cancelledTrips),
          style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (ready, unread) = context.select(
      (NotificationsCubit c) => (c.state.status == NotificationsStatus.ready, c.state.unreadCount),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.profileEdit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Badge(
              isLabelVisible: ready && unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            title: Text(l10n.accountNotifications),
            subtitle: ready ? Text(l10n.notificationsUnreadCount(unread)) : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.settingsTitle),
            subtitle: Text('${l10n.settingsLanguage} · ${l10n.settingsTheme} · ${l10n.settingsSectionNotifications}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.background, required this.foreground});

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
            Text(label, style: context.textStyles.labelSmall?.copyWith(color: foreground)),
          ],
        ),
      );
}

class _SignOutButton extends StatefulWidget {
  const _SignOutButton();

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _busy = false;

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountSignOutConfirmTitle),
        content: Text(l10n.accountSignOutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.accountSignOut)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<SessionCubit>().signOut();
    if (outcome == SignOutOutcome.signedOutLocally) showAfterSignOut(messenger, l10n.accountSignedOutLocally);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => AppButton(
        label: context.l10n.accountSignOut,
        icon: Icons.logout,
        variant: AppButtonVariant.outlined,
        loading: _busy,
        onPressed: _signOut,
      );
}

/// Permanent, in-app account deletion. Asks for explicit confirmation; the
/// account is only reported as deleted after the server removed it.
class _DeleteAccountButton extends StatefulWidget {
  const _DeleteAccountButton();

  @override
  State<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<_DeleteAccountButton> {
  bool _busy = false;

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final session = context.read<SessionCubit>();
    final account = context.read<AccountRepository>();
    final recentlyViewed = context.read<RecentlyViewedStore>();
    final userId = session.state.user?.id;
    try {
      await session.deleteAccount(account.deleteMyAccount);
      // Device-local traces of the account go too.
      if (userId != null) await recentlyViewed.clear(userId);
      showAfterSignOut(messenger, l10n.accountDeleted);
    } on AppFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleteFailed(failure.message(l10n)))));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => _busy
      ? const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
        )
      : TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          onPressed: _delete,
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(context.l10n.accountDelete),
        );
}

/// Shows [text] on the root messenger once the sign-out has settled: the
/// router moves to sign-in and app-wide listeners clear the previous
/// account's snack bars first, so an earlier snack bar would be lost.
void showAfterSignOut(ScaffoldMessengerState messenger, String text) {
  WidgetsBinding.instance
    ..addPostFrameCallback((_) {
      if (messenger.mounted) messenger.showSnackBar(SnackBar(content: Text(text)));
    })
    ..scheduleFrame();
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: context.colors.error),
      title: Text(l10n.accountDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountDeleteBody),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            value: _understood,
            onChanged: (v) => setState(() => _understood = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.accountDeleteConfirmCheck, style: context.textStyles.bodyMedium),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError),
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          child: Text(l10n.accountDeleteCta),
        ),
      ],
    );
  }
}
