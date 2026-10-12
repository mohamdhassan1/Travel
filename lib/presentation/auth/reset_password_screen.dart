import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/inline_message.dart';
import '../../data/repositories/auth_repository.dart';
import '../../logic/auth/auth_form_cubits.dart';
import '../../logic/auth/session_cubit.dart';
import '../common/l10n_extensions.dart';
import 'widgets/auth_scaffold.dart';

/// Reached from a password-recovery link (recovery session) or by a
/// signed-in user who wants to change their password.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => NewPasswordCubit(context.read<AuthRepository>()),
        child: const _ResetPasswordView(),
      );
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<NewPasswordCubit>().submit(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<NewPasswordCubit, SubmitState<void>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          context.showSnack(l10n.resetSuccess);
          final session = context.read<SessionCubit>();
          if (session.state.passwordRecovery) {
            // Leaving recovery mode lets the router continue into the app.
            session.completePasswordRecovery();
          } else if (context.canPop()) {
            context.pop();
          }
        }
      },
      builder: (context, state) {
        final failure = state.status == SubmitStatus.failure ? state.failure : null;
        // Recovery link: the user must finish here. Otherwise a signed-in
        // user opened "Change password" and may go back.
        final recovery = context.select((SessionCubit c) => c.state.passwordRecovery);
        return AuthScaffold(
          title: recovery ? l10n.resetTitle : l10n.changePasswordTitle,
          subtitle: recovery ? l10n.resetSubtitle : l10n.changePasswordSubtitle,
          showBack: !recovery,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (failure != null) ...[
                  InlineMessage(message: failure.message(l10n)),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  controller: _password,
                  label: l10n.authNewPasswordLabel,
                  prefixIcon: Icons.lock_outline,
                  helperText: l10n.authPasswordRequirements,
                  isPassword: true,
                  showPasswordLabel: l10n.authShowPassword,
                  hidePasswordLabel: l10n.authHidePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: localizedValidator(
                    context,
                    Validators.newPassword,
                  ),
                  enabled: !state.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _confirm,
                  label: l10n.authConfirmPasswordLabel,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  showPasswordLabel: l10n.authShowPassword,
                  hidePasswordLabel: l10n.authHidePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: localizedValidator(
                    context,
                    (v) => Validators.confirmPassword(v, _password.text),
                  ),
                  enabled: !state.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.resetButton,
                  loading: state.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
