import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_view.dart';
import '../../logic/auth/session_cubit.dart';
import '../../logic/common/load_state.dart';
import '../../logic/profile/profile_cubit.dart';
import '../common/l10n_extensions.dart';
import 'widgets/profile_photo_actions.dart';
import 'widgets/user_avatar.dart';

/// Edit the `profiles` row: name and phone (and the photo). Email and
/// password are deliberately not here — email is the sign-in identity and the
/// password has its own reset flow — so nothing can be overwritten by
/// accident.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ProfileCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEdit)),
      body: switch (state.status) {
        LoadStatus.success when state.profile != null => _EditForm(key: ValueKey(state.profile!.id)),
        LoadStatus.failure => StatusView(
            icon: Icons.cloud_off_outlined,
            tone: StatusTone.error,
            title: l10n.profileLoadError,
            message: state.failure?.message(l10n),
            actionLabel: l10n.commonRetry,
            onAction: context.read<ProfileCubit>().load,
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EditForm extends StatefulWidget {
  const _EditForm({super.key});

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<ProfileCubit>().state.profile!.fullName);
  late final _phone = TextEditingController(text: context.read<ProfileCubit>().state.profile!.phone ?? '');

  bool get _dirty {
    final p = context.read<ProfileCubit>().state.profile!;
    return _name.text.trim() != p.fullName.trim() || _phone.text.trim() != (p.phone ?? '');
  }

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _phone.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.read<ProfileCubit>().save(fullName: _name.text, phone: _phone.text);
    if (ok && mounted && context.canPop()) context.pop();
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDiscardTitle),
        content: Text(l10n.profileDiscardBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.profileKeepEditing)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.profileDiscard)),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ProfileCubit>().state;
    final email = context.select((SessionCubit c) => c.state.user?.email ?? '');
    final dirty = _dirty;

    return PopScope(
      canPop: !dirty || state.saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _name.text = state.profile!.fullName;
          _phone.text = state.profile!.phone ?? '';
          context.pop();
        }
      },
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          AnimatedOpacity(
                            opacity: state.photoBusy ? 0.5 : 1,
                            duration: AppDurations.medium,
                            child: const UserAvatar(radius: 52),
                          ),
                          if (state.photoBusy)
                            const Positioned.fill(child: Center(child: CircularProgressIndicator(strokeWidth: 3))),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton.icon(
                        onPressed: state.photoBusy ? null : () => showProfilePhotoActions(context),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(l10n.profilePhotoChange),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _name,
                      label: l10n.authFullNameLabel,
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      maxLength: Validators.maxNameLength,
                      validator: localizedValidator(context, ProfileValidators.fullName),
                      enabled: !state.saving,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _phone,
                      label: l10n.profilePhoneLabel,
                      hint: l10n.profilePhoneHint,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      maxLength: 20,
                      validator: localizedValidator(context, ProfileValidators.phone),
                      onSubmitted: (_) => _save(),
                      enabled: !state.saving,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.authEmailLabel,
                        prefixIcon: const Icon(Icons.mail_outline),
                        helperText: l10n.profileEmailReadOnly,
                        enabled: false,
                      ),
                      child: Text(email, textDirection: ui.TextDirection.ltr),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: l10n.profileSave,
                      icon: Icons.check,
                      loading: state.saving,
                      onPressed: dirty ? _save : null,
                    ),
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
