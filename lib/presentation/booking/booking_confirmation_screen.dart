import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/status_view.dart';
import '../../data/repositories/booking_repository.dart';
import '../../logic/auth/session_cubit.dart';
import '../../logic/booking/booking_details_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/booking_widgets.dart';

/// Shown after Supabase created the booking. Everything displayed — the
/// reference, prices and status — is read back from the stored row.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) =>
            BookingDetailsCubit(context.read<BookingRepository>(), context.read<SessionCubit>(), bookingId)..load(),
        child: const _ConfirmationView(),
      );
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.select((BookingDetailsCubit c) => c.state.booking);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: switch (state.status) {
        LoadStatus.loading || LoadStatus.empty => const Center(child: CircularProgressIndicator()),
        LoadStatus.failure => StatusView(
            icon: Icons.cloud_off_outlined,
            tone: StatusTone.error,
            title: state.failure!.type == FailureType.notFound ? l10n.bookingNotFoundTitle : l10n.bookingErrorTitle,
            message: state.failure!.message(l10n),
            actionLabel: l10n.commonRetry,
            onAction: context.read<BookingDetailsCubit>().load,
            // Never a dead end: the booking (if it was stored) is in Trips.
            secondaryActionLabel: l10n.bookingViewMyBookings,
            onSecondaryAction: () => context.go(AppRoutes.bookings),
          ),
        LoadStatus.success => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(color: context.palette.successContainer, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, size: 48, color: context.palette.onSuccessContainer),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.bookingConfirmedTitle,
                        textAlign: TextAlign.center,
                        style: context.textStyles.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.bookingConfirmedBody,
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(child: Text(l10n.bookingReference, style: context.textStyles.labelLarge)),
                      Center(child: BookingReferenceText(state.data!.reference, large: true)),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: BookingTripHeader(booking: state.data!),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      BookingFactsCard(booking: state.data!),
                      const SizedBox(height: AppSpacing.md),
                      InlineMessage(message: l10n.bookingNoPaymentNote, tone: InlineMessageTone.info),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: l10n.bookingViewMyBookings,
                        icon: Icons.luggage_outlined,
                        // The Trips tab (with the bottom bar), so it is never a
                        // dead end.
                        onPressed: () => context.go(AppRoutes.bookings),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: l10n.bookingDone,
                        variant: AppButtonVariant.text,
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }
}
