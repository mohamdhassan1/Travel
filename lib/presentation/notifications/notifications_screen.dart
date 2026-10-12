import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/status_view.dart';
import '../../data/models/app_notification.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/notifications/notifications_cubit.dart';
import '../../routing/app_routes.dart';
import '../booking/widgets/booking_widgets.dart' show formatShortDate;
import '../common/l10n_extensions.dart';

/// The signed-in user's notifications, created by the database when a
/// booking is confirmed or cancelled. Read state comes from the server.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // The app-level cubit may hold a list from earlier; fetch what's new.
    context.read<NotificationsCubit>().refresh();
  }

  void _open(BuildContext context, AppNotification notification) {
    final cubit = context.read<NotificationsCubit>();
    if (!notification.isRead) cubit.markRead(notification.id);
    final bookingId = notification.bookingId;
    if (bookingId != null) context.push(AppRoutes.booking(bookingId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<NotificationsCubit>();
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (a, b) => b.lastActionFailure != null && a.lastActionFailure != b.lastActionFailure,
      listener: (context, state) =>
          context.showSnack(l10n.notificationsActionFailed(state.lastActionFailure!.failure.message(l10n))),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.notificationsTitle),
          actions: [
            if (state.status == NotificationsStatus.ready && state.items.isNotEmpty)
              state.markingAll
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.done_all),
                      tooltip: l10n.notificationsMarkAllRead,
                      onPressed: state.unreadCount == 0 ? null : cubit.markAllRead,
                    ),
          ],
        ),
        body: switch (state.status) {
          NotificationsStatus.signedOut ||
          NotificationsStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          NotificationsStatus.failure => StatusView(
              icon: Icons.cloud_off_outlined,
              tone: StatusTone.error,
              title: l10n.notificationsErrorTitle,
              message: state.failure!.message(l10n),
              actionLabel: l10n.commonRetry,
              onAction: cubit.load,
            ),
          NotificationsStatus.ready => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: state.items.isEmpty
                  ? LayoutBuilder(
                      // Scrollable so pull-to-refresh also works when empty.
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: StatusView(
                            icon: Icons.notifications_none_outlined,
                            title: l10n.notificationsEmptyTitle,
                            message: l10n.notificationsEmptyBody,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = state.items[index];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
                            child: NotificationTile(
                              notification: notification,
                              onTap: () => _open(context, notification),
                            ),
                          ),
                        );
                      },
                    ),
            ),
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final unread = !notification.isRead;
    final (icon, tint) = switch (notification.type) {
      NotificationType.bookingConfirmed => (Icons.event_available_outlined, context.palette.success),
      NotificationType.bookingCancelled => (Icons.event_busy_outlined, colors.error),
      NotificationType.tripReminder => (Icons.alarm_outlined, colors.primary),
    };
    final locale = Localizations.localeOf(context);
    final received = DateFormat.yMMMd(locale.toLanguageTag()).add_jm().format(notification.createdAt.toLocal());

    return Semantics(
      label: unread ? l10n.notificationUnread : null,
      child: Material(
        color: unread ? colors.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxs),
          leading: CircleAvatar(
            backgroundColor: tint.withValues(alpha: 0.14),
            foregroundColor: tint,
            child: Icon(icon),
          ),
          title: Text(
            notificationTitle(l10n, notification.type),
            style: context.textStyles.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notificationBody(context, notification) case final body?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(body, style: context.textStyles.bodyMedium),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  received,
                  style: context.textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unread)
                Container(
                  key: const ValueKey('unread-dot'),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                ),
              if (notification.bookingId != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String notificationTitle(AppLocalizations l10n, NotificationType type) => switch (type) {
      NotificationType.bookingConfirmed => l10n.notificationBookingConfirmedTitle,
      NotificationType.bookingCancelled => l10n.notificationBookingCancelledTitle,
      NotificationType.tripReminder => l10n.notificationTripReminderTitle,
    };

/// Built only from what the database stored; parts that are missing are
/// left out rather than guessed.
String? notificationBody(BuildContext context, AppNotification n) {
  final l10n = context.l10n;
  final destination = n.destinationName(Localizations.localeOf(context).languageCode);
  final date = n.travelDate == null ? null : formatShortDate(context, n.travelDate!);
  // Booking references are Latin (RH-…); keep them left-to-right in Arabic.
  final reference = n.reference == null ? null : '$_lri${n.reference}$_pdi';
  final trip = switch ((destination, date)) {
    (final d?, final t?) => l10n.notificationTripOn(d, t),
    (final d?, null) => d,
    (null, final t?) => t,
    (null, null) => null,
  };
  return switch ((trip, reference)) {
    (final t?, final r?) => '$t · ${l10n.notificationReference(r)}',
    (final t?, null) => t,
    (null, final r?) => l10n.notificationReference(r),
    (null, null) => null,
  };
}

/// Left-to-right isolate / pop directional isolate (U+2066 / U+2069).
final _lri = String.fromCharCode(0x2066);
final _pdi = String.fromCharCode(0x2069);
