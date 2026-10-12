import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_view.dart';
import '../../data/models/booking.dart';
import '../../logic/booking/my_bookings_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/booking_widgets.dart';

enum BookingFilter { upcoming, past, cancelled }

/// The Trips tab: the signed-in user's bookings, grouped by Upcoming / Past
/// (by date) / Cancelled (by database status). Uses the app-wide
/// [MyBookingsCubit] (also behind Home's next trip and profile statistics).
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _MyBookingsView();
}

class _MyBookingsView extends StatefulWidget {
  const _MyBookingsView();

  @override
  State<_MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<_MyBookingsView> {
  BookingFilter _filter = BookingFilter.upcoming;

  @override
  void initState() {
    super.initState();
    // Quietly refresh what's on screen; an error stays visible until retried.
    final cubit = context.read<MyBookingsCubit>();
    if (cubit.state.status == LoadStatus.success) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MyBookingsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myBookingsTitle)),
      body: BlocBuilder<MyBookingsCubit, LoadState<List<Booking>>>(
        builder: (context, state) => switch (state.status) {
          LoadStatus.loading => const Center(child: CircularProgressIndicator()),
          LoadStatus.failure => StatusView(
              icon: Icons.cloud_off_outlined,
              tone: StatusTone.error,
              title: l10n.myBookingsErrorTitle,
              message: state.failure!.message(l10n),
              actionLabel: l10n.commonRetry,
              onAction: cubit.load,
            ),
          LoadStatus.empty => StatusView(
              icon: Icons.luggage_outlined,
              title: l10n.myBookingsEmptyTitle,
              message: l10n.myBookingsEmptyBody,
              actionLabel: l10n.accountBrowseDestinations,
              onAction: () => context.go(AppRoutes.explore),
            ),
          LoadStatus.success => _list(context, state.data!),
        },
      ),
    );
  }

  Widget _list(BuildContext context, List<Booking> all) {
    final l10n = context.l10n;
    final today = serverToday();
    final visible = switch (_filter) {
      BookingFilter.upcoming => all.where((b) => b.isUpcoming(today)).toList(),
      // Most recent past trip first.
      BookingFilter.past => all.where((b) => b.isPast(today)).toList().reversed.toList(),
      BookingFilter.cancelled => all.where((b) => b.isCancelled).toList(),
    };
    final emptyText = switch (_filter) {
      BookingFilter.upcoming => l10n.myBookingsNoUpcoming,
      BookingFilter.past => l10n.myBookingsNoPast,
      BookingFilter.cancelled => l10n.myBookingsNoCancelled,
    };

    return RefreshIndicator(
      onRefresh: context.read<MyBookingsCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<BookingFilter>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: BookingFilter.upcoming, label: Text(l10n.myBookingsFilterUpcoming)),
                      ButtonSegment(value: BookingFilter.past, label: Text(l10n.myBookingsFilterPast)),
                      ButtonSegment(value: BookingFilter.cancelled, label: Text(l10n.myBookingsFilterCancelled)),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    )
                  else
                    for (final booking in visible) ...[
                      _BookingCard(booking: booking, today: today),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.today});

  final Booking booking;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // A cancellation on the details screen refreshes this list through
        // the shared cubit's change stream; no extra request is needed here.
        onTap: () => context.push(AppRoutes.booking(booking.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookingTripHeader(booking: booking),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  BookingStatusChip(booking: booking, today: today),
                  const Spacer(),
                  BookingReferenceText(booking.reference),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(child: Text(formatShortDate(context, booking.travelDate))),
                  Icon(Icons.group_outlined, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(l10n.bookingTravelersCount(booking.travelers)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  formatPrice(booking.totalPrice, booking.currency, localeTag),
                  style: context.textStyles.titleMedium?.copyWith(color: context.colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
