import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/status_view.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../logic/auth/auth_form_cubits.dart' show SubmitStatus;
import '../../logic/auth/session_cubit.dart';
import '../../logic/booking/booking_details_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/booking_widgets.dart';

/// One booking with everything the database stores about it, plus
/// cancellation through the `cancel_booking` function.
class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) =>
            BookingDetailsCubit(context.read<BookingRepository>(), context.read<SessionCubit>(), bookingId)..load(),
        child: const _DetailsView(),
      );
}

class _DetailsView extends StatelessWidget {
  const _DetailsView();

  Future<void> _confirmCancel(BuildContext context, Booking booking) async {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final cubit = context.read<BookingDetailsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bookingCancelConfirmTitle),
        content: Text(l10n.bookingCancelConfirmBody(
          booking.destination?.name(lang) ?? booking.reference,
          formatLongDate(context, booking.travelDate),
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.bookingCancelKeep)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.bookingCancelCta),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<BookingDetailsCubit, BookingDetailsState>(
      listenWhen: (a, b) => a.cancellation.status != b.cancellation.status,
      listener: (context, state) {
        // Announced only after the database confirmed (or rejected) it.
        if (state.cancellation.status == SubmitStatus.success) context.showSnack(l10n.bookingCancelledToast);
        if (state.cancellation.status == SubmitStatus.failure) {
          context.showSnack(l10n.bookingCancelFailed(state.cancellation.failure!.message(l10n)));
        }
      },
      builder: (context, state) {
        final booking = state.booking;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.bookingDetailsTitle)),
          body: switch (booking.status) {
            LoadStatus.loading || LoadStatus.empty => const Center(child: CircularProgressIndicator()),
            LoadStatus.failure => booking.failure!.type == FailureType.notFound
                ? StatusView(
                    icon: Icons.search_off_outlined,
                    title: l10n.bookingNotFoundTitle,
                    message: l10n.bookingNotFoundBody,
                    actionLabel: l10n.bookingViewMyBookings,
                    onAction: () => context.canPop() ? context.pop() : context.go(AppRoutes.bookings),
                  )
                : StatusView(
                    icon: Icons.cloud_off_outlined,
                    tone: StatusTone.error,
                    title: l10n.bookingErrorTitle,
                    message: booking.failure!.message(l10n),
                    actionLabel: l10n.commonRetry,
                    onAction: context.read<BookingDetailsCubit>().load,
                  ),
            LoadStatus.success => _content(context, booking.data!, state.isCancelling),
          },
        );
      },
    );
  }

  Widget _content(BuildContext context, Booking booking, bool cancelling) {
    final l10n = context.l10n;
    final today = serverToday();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BookingTripHeader(booking: booking, imageSize: 72),
                        // Still in the catalog: one tap back to the destination.
                        if (booking.destination != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: () => context.push(AppRoutes.destination(booking.destinationId)),
                              icon: const Icon(Icons.place_outlined, size: AppSizes.iconSm),
                              label: Text(l10n.bookingViewDestination),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        // Wraps onto two lines with large text instead of overflowing.
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            BookingStatusChip(booking: booking, today: today),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.bookingReference, style: context.textStyles.labelSmall),
                                const SizedBox(width: AppSpacing.xs),
                                BookingReferenceText(booking.reference),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                BookingFactsCard(booking: booking),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.bookingContact, style: context.textStyles.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        SummaryRow(label: l10n.bookingContactName, value: booking.contactName),
                        SummaryRow(
                          label: l10n.bookingContactPhone,
                          value: booking.contactPhone,
                          valueDirection: ui.TextDirection.ltr,
                        ),
                        if (booking.specialRequests != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.bookingSpecialRequests, style: context.textStyles.labelLarge),
                          Text(booking.specialRequests!, style: context.textStyles.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.bookingBookedOn(formatShortDate(context, booking.createdAt.toLocal())),
                  style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                if (booking.cancelledAt != null)
                  Text(
                    l10n.bookingCancelledOn(formatShortDate(context, booking.cancelledAt!.toLocal())),
                    style: context.textStyles.bodySmall?.copyWith(color: context.colors.error),
                  ),
                const SizedBox(height: AppSpacing.md),
                InlineMessage(message: l10n.bookingNoPaymentNote, tone: InlineMessageTone.info),
                const SizedBox(height: AppSpacing.lg),
                if (booking.canCancel(today))
                  AppButton(
                    label: l10n.bookingCancelCta,
                    icon: Icons.event_busy_outlined,
                    variant: AppButtonVariant.outlined,
                    loading: cancelling,
                    onPressed: () => _confirmCancel(context, booking),
                  ),
                if (!booking.isCancelled)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l10n.bookingCancelPolicy,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
