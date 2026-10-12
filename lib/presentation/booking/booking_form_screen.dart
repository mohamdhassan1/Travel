import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/status_view.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/booking_request_id_store.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../logic/auth/auth_form_cubits.dart' show SubmitStatus;
import '../../logic/auth/session_cubit.dart';
import '../../logic/booking/booking_form_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../logic/notifications/device_notifications_cubit.dart';
import '../../logic/profile/profile_cubit.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/booking_widgets.dart';

/// Booking flow for one destination: choose package, date and travellers,
/// enter contact details, review, then submit to Supabase.
class BookingFormScreen extends StatelessWidget {
  const BookingFormScreen({super.key, required this.destinationId, this.initialPackageId});

  final String destinationId;
  final String? initialPackageId;

  @override
  Widget build(BuildContext context) {
    // Prefill only a real name from the account (never the email's local part).
    // The name stored in `profiles` (what the user edits), else the account's.
    final profile = context.read<ProfileCubit>().state.profile;
    final profileName = profile?.fullName.trim() ?? '';
    final fullName =
        profileName.isNotEmpty ? profileName : context.read<SessionCubit>().state.user?.fullName?.trim() ?? '';
    return BlocProvider(
      create: (context) => BookingFormCubit(
        catalog: context.read<CatalogRepository>(),
        bookings: context.read<BookingRepository>(),
        requestIds: context.read<BookingRequestIdStore>(),
        destinationId: destinationId,
        initialPackageId: initialPackageId,
        initialContactName: fullName,
        // The phone the user saved on their profile, if any (still editable).
        initialContactPhone: profile?.phone?.trim() ?? '',
      )..load(),
      child: const _BookingFormView(),
    );
  }
}

class _BookingFormView extends StatefulWidget {
  const _BookingFormView();

  @override
  State<_BookingFormView> createState() => _BookingFormViewState();
}

class _BookingFormViewState extends State<_BookingFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _notes = TextEditingController();
  bool _showSelectionErrors = false;

  @override
  void initState() {
    super.initState();
    final initial = context.read<BookingFormCubit>().state;
    _name = TextEditingController(text: initial.contactName);
    _phone = TextEditingController(text: initial.contactPhone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _review() {
    FocusScope.of(context).unfocus();
    setState(() => _showSelectionErrors = true);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid) return;
    context.read<BookingFormCubit>().review(
          contactName: _name.text,
          contactPhone: _phone.text,
          specialRequests: _notes.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The profile may finish loading after the form opened (e.g. a deep
    // link): fill contact fields the user hasn't typed into yet.
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => a.profile == null && b.profile != null,
      listener: (context, profileState) {
        final p = profileState.profile!;
        if (_name.text.trim().isEmpty && p.fullName.trim().isNotEmpty) _name.text = p.fullName.trim();
        if (_phone.text.trim().isEmpty && (p.phone?.trim().isNotEmpty ?? false)) _phone.text = p.phone!.trim();
      },
      child: BlocConsumer<BookingFormCubit, BookingFormState>(
        listenWhen: (a, b) => a.submission.status != b.submission.status && b.submission.status == SubmitStatus.success,
        listener: (context, state) {
          // Only now — after Supabase returned the stored booking — show success.
          context.pushReplacement(AppRoutes.bookingConfirmation(state.submission.result!.id));
          // First booking: ask (once) whether reminders may be shown.
          context.read<DeviceNotificationsCubit>().requestPermissionAfterBooking();
        },
        builder: (context, state) {
          final cubit = context.read<BookingFormCubit>();
          final Widget body;
          if (state.destination.status == LoadStatus.loading) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.destination.status == LoadStatus.failure) {
            final notFound = state.destination.failure!.type == FailureType.notFound;
            body = StatusView(
              icon: notFound ? Icons.explore_off_outlined : Icons.cloud_off_outlined,
              tone: notFound ? StatusTone.neutral : StatusTone.error,
              title: notFound ? l10n.detailsNotFoundTitle : l10n.bookingLoadErrorTitle,
              message: notFound ? l10n.detailsNotFoundBody : state.destination.failure!.message(l10n),
              actionLabel: notFound ? l10n.detailsBackToDestinations : l10n.commonRetry,
              onAction: notFound ? () => context.go(AppRoutes.destinations) : cubit.load,
            );
          } else if (state.packages.status == LoadStatus.empty) {
            body = StatusView(icon: Icons.event_busy_outlined, title: l10n.bookingNoPackages);
          } else {
            body = state.step == BookingStep.details ? _detailsStep(context, state) : _ReviewStep(state: state);
          }

          return PopScope(
            // Leaving mid-submission could hide the outcome of a real request;
            // back from the review step returns to the details step.
            canPop: !state.isSubmitting && state.step == BookingStep.details,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && !state.isSubmitting && state.step == BookingStep.review) cubit.backToDetails();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(state.step == BookingStep.review ? l10n.bookingReviewTitle : l10n.bookingTitle),
              ),
              body: body,
            ),
          );
        },
      ),
    );
  }

  Widget _detailsStep(BuildContext context, BookingFormState state) {
    final l10n = context.l10n;
    final cubit = context.read<BookingFormCubit>();
    final destination = state.destination.data!;
    final packages = state.packages.data ?? const <TravelPackage>[];
    final lang = Localizations.localeOf(context).languageCode;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final selected = state.selectedPackage;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Constrained(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.mdAll,
                      child: SizedBox.square(
                        dimension: 56,
                        child: AppNetworkImage(url: destination.coverImage, cacheWidth: 56),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(destination.name(lang), style: context.textStyles.titleLarge),
                          Text(
                            destination.country(lang),
                            style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel(l10n.bookingPackageLabel),
                RadioGroup<String>(
                  groupValue: state.packageId,
                  onChanged: (id) => id == null ? null : cubit.selectPackage(id),
                  child: Column(
                    children: [
                      for (final p in packages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.lgAll,
                              side: BorderSide(
                                color: p.id == state.packageId ? context.colors.primary : context.colors.outlineVariant,
                                width: p.id == state.packageId ? 1.6 : 1,
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: p.id,
                              title: Text(p.name(lang), style: context.textStyles.titleSmall),
                              subtitle: Text(
                                '${l10n.destinationDays(p.durationDays)} · '
                                '${formatPrice(p.pricePerPerson, p.currency, localeTag)} ${l10n.destinationPerPerson}',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_showSelectionErrors && selected == null) _FieldErrorText(l10n.bookingPackageRequired),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(l10n.bookingTravelDateLabel),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(alignment: AlignmentDirectional.centerStart),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: cubit.firstTravelDate,
                      lastDate: cubit.lastTravelDate,
                      initialDate: state.travelDate ?? cubit.firstTravelDate,
                      helpText: l10n.bookingTravelDateLabel,
                    );
                    if (picked != null) cubit.setTravelDate(picked);
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    state.travelDate == null ? l10n.bookingTravelDatePick : formatLongDate(context, state.travelDate!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(l10n.bookingTravelDateHint, style: context.textStyles.bodySmall),
                ),
                if (_showSelectionErrors && state.travelDate == null) _FieldErrorText(l10n.bookingTravelDateRequired),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(l10n.bookingTravelersLabel),
                _TravelersStepper(
                  value: state.travelers,
                  max: selected?.maxTravelers ?? 1,
                  enabled: selected != null,
                  onChanged: cubit.setTravelers,
                ),
                if (selected != null)
                  Text(l10n.bookingTravelersMax(selected.maxTravelers), style: context.textStyles.bodySmall),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel(l10n.bookingContactSection),
                AppTextField(
                  controller: _name,
                  label: l10n.bookingContactName,
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: Validators.maxNameLength,
                  validator: localizedValidator(context, BookingValidators.contactName),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: l10n.bookingContactPhone,
                  hint: l10n.bookingContactPhoneHint,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  maxLength: 20,
                  validator: localizedValidator(context, BookingValidators.contactPhone),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  maxLength: BookingValidators.maxSpecialRequestsLength,
                  validator: localizedValidator(context, BookingValidators.specialRequests),
                  decoration: InputDecoration(
                    labelText: l10n.bookingSpecialRequests,
                    hintText: l10n.bookingSpecialRequestsHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: l10n.bookingContinueToReview, icon: Icons.arrow_forward, onPressed: _review),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final BookingFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BookingFormCubit>();
    final lang = Localizations.localeOf(context).languageCode;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final destination = state.destination.data!;
    final pkg = state.selectedPackage!;
    final failure = state.submission.status == SubmitStatus.failure ? state.submission.failure : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Constrained(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(destination.name(lang), style: context.textStyles.titleLarge),
                      Text(
                        '${pkg.name(lang)} · ${l10n.destinationDays(pkg.durationDays)}',
                        style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      const Divider(height: AppSpacing.xl),
                      SummaryRow(label: l10n.bookingTravelDateLabel, value: formatLongDate(context, state.travelDate!)),
                      SummaryRow(label: l10n.bookingTravelersLabel, value: l10n.bookingTravelersCount(state.travelers)),
                      SummaryRow(
                        label: l10n.bookingPricePerPerson,
                        value: formatPrice(pkg.pricePerPerson, pkg.currency, localeTag),
                      ),
                      const Divider(height: AppSpacing.lg),
                      SummaryRow(
                        label: l10n.bookingTotal,
                        value: formatPrice(state.estimatedTotal!, pkg.currency, localeTag),
                        emphasize: true,
                      ),
                      Text(l10n.bookingTotalNote, style: context.textStyles.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.bookingContactSection, style: context.textStyles.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      SummaryRow(label: l10n.bookingContactName, value: state.contactName),
                      SummaryRow(
                        label: l10n.bookingContactPhone,
                        value: state.contactPhone,
                        valueDirection: ui.TextDirection.ltr,
                      ),
                      if (state.specialRequests.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.bookingSpecialRequests, style: context.textStyles.labelLarge),
                        Text(state.specialRequests, style: context.textStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InlineMessage(message: l10n.bookingNoPaymentNote, tone: InlineMessageTone.info),
              if (failure != null) ...[
                const SizedBox(height: AppSpacing.md),
                InlineMessage(message: failure.message(l10n)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.bookingConfirmCta,
                icon: Icons.check,
                loading: state.isSubmitting,
                onPressed: cubit.submit,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: l10n.bookingReviewEdit,
                variant: AppButtonVariant.text,
                onPressed: state.isSubmitting ? null : cubit.backToDetails,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TravelersStepper extends StatelessWidget {
  const _TravelersStepper({required this.value, required this.max, required this.enabled, required this.onChanged});

  final int value;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: l10n.bookingTravelersDecrease,
          onPressed: enabled && value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        // Flexible: with large text the label wraps instead of overflowing.
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.bookingTravelersCount(value),
                textAlign: TextAlign.center,
                style: context.textStyles.titleMedium,
              ),
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: l10n.bookingTravelersIncrease,
          onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Semantics(header: true, child: Text(text, style: context.textStyles.titleMedium)),
      );
}

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Text(text, style: context.textStyles.bodySmall?.copyWith(color: context.colors.error)),
      );
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth), child: child),
      );
}
