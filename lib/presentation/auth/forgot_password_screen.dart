import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/inline_message.dart';
import '../../data/repositories/auth_repository.dart';
import '../../logic/auth/auth_form_cubits.dart';
import '../common/l10n_extensions.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/resend_cooldown_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => PasswordResetRequestCubit(context.read<AuthRepository>()),
        child: const _ForgotPasswordView(),
      );
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// Set after the first successful request; the form then shows a
  /// confirmation (and later requests are resends).
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<bool> _send() async {
    final cubit = context.read<PasswordResetRequestCubit>();
    await cubit.submit(_email.text);
    final ok = cubit.state.status == SubmitStatus.success;
    if (ok && mounted) setState(() => _sentTo = _email.text.trim());
    return ok;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) _send();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<PasswordResetRequestCubit, SubmitState<void>>(
      builder: (context, state) {
        final failure = state.status == SubmitStatus.failure ? state.failure : null;
        final sentTo = _sentTo;
        return AuthScaffold(
          showBack: true,
          title: sentTo == null ? l10n.forgotTitle : l10n.forgotSentTitle,
          subtitle: sentTo == null ? l10n.forgotSubtitle : l10n.forgotSentBody(sentTo),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (failure != null) ...[
                  InlineMessage(message: failure.message(l10n)),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (sentTo == null) ...[
                  AppTextField(
                    controller: _email,
                    label: l10n.authEmailLabel,
                    hint: l10n.authEmailHint,
                    prefixIcon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _submit(),
                    validator: localizedValidator(context, Validators.email),
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.forgotButton,
                    loading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ] else ...[
                  ResendCooldownButton(
                    loading: state.isSubmitting,
                    onPressed: _send,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: l10n.registerBackToSignIn,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
