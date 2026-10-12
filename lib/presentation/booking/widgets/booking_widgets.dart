import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/booking.dart';
import '../../common/l10n_extensions.dart';

/// Long, locale-aware date (e.g. "Thursday, 15 October 2026").
String formatLongDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toLanguageTag()).format(date);

String formatShortDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date);

/// Shows the database status (Confirmed / Cancelled). "Past trip" is a
/// separate, date-derived label — the database has no "completed" status.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.booking, required this.today});

  final Booking booking;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final palette = context.palette;
    final (label, bg, fg, icon) = booking.isCancelled
        ? (l10n.bookingStatusCancelled, colors.errorContainer, colors.onErrorContainer, Icons.cancel_outlined)
        : booking.isPast(today)
            ? (l10n.bookingPastTrip, colors.surfaceContainerHigh, colors.onSurfaceVariant, Icons.history)
            : (
                l10n.bookingStatusConfirmed,
                palette.successContainer,
                palette.onSuccessContainer,
                Icons.check_circle_outline
              );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: context.textStyles.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Reference in a monospaced, left-to-right, selectable style.
class BookingReferenceText extends StatelessWidget {
  const BookingReferenceText(this.reference, {super.key, this.large = false});

  final String reference;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = (large ? context.textStyles.headlineSmall : context.textStyles.labelLarge)
        ?.copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()], letterSpacing: 1);
    return SelectableText(reference, style: style, textDirection: ui.TextDirection.ltr);
  }
}

/// A label/value row used in summaries.
class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value, this.emphasize = false, this.valueDirection});

  final String label;
  final String value;
  final bool emphasize;
  final ui.TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final valueStyle = emphasize
        ? context.textStyles.titleMedium?.copyWith(color: context.colors.primary)
        : context.textStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              // Align to the row's visual end even when the value itself is
              // forced LTR (e.g. a phone number inside an Arabic layout).
              textAlign: Directionality.of(context) == ui.TextDirection.rtl ? TextAlign.left : TextAlign.right,
              textDirection: valueDirection,
            ),
          ),
        ],
      ),
    );
  }
}

/// Destination thumbnail + name/country + package name. Falls back honestly
/// when the catalog item is no longer visible.
class BookingTripHeader extends StatelessWidget {
  const BookingTripHeader({super.key, required this.booking, this.imageSize = 64});

  final Booking booking;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final destination = booking.destination;
    final package = booking.package;
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: SizedBox.square(
            dimension: imageSize,
            child: destination == null
                ? ColoredBox(
                    color: context.colors.surfaceContainerHigh,
                    child: Icon(Icons.image_not_supported_outlined, color: context.colors.onSurfaceVariant),
                  )
                : AppNetworkImage(
                    url: destination.coverImage,
                    cacheWidth: imageSize.round(),
                    errorLabel: l10n.destinationImageUnavailable,
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination?.name(lang) ?? l10n.bookingCatalogItemUnavailable,
                style: context.textStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (destination != null)
                Text(
                  destination.country(lang),
                  style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                package == null
                    ? l10n.bookingCatalogItemUnavailable
                    : '${package.name(lang)} · ${l10n.destinationDays(package.durationDays)}',
                style: context.textStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Trip date, travellers and the price figures stored by the database.
class BookingFactsCard extends StatelessWidget {
  const BookingFactsCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            SummaryRow(label: l10n.bookingTravelDateLabel, value: formatLongDate(context, booking.travelDate)),
            SummaryRow(label: l10n.bookingTravelersLabel, value: l10n.bookingTravelersCount(booking.travelers)),
            SummaryRow(
              label: l10n.bookingPricePerPerson,
              value: formatPrice(booking.unitPrice, booking.currency, localeTag),
            ),
            const Divider(height: AppSpacing.lg),
            SummaryRow(
              label: l10n.bookingTotal,
              value: formatPrice(booking.totalPrice, booking.currency, localeTag),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}
