import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/inline_message.dart';
import '../../core/widgets/status_view.dart';
import '../../data/repositories/auth_repository.dart';
import '../../logic/auth/auth_form_cubits.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/resend_cooldown_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RegisterCubit(auth)),
        BlocProvider(create: (_) => ResendConfirmationCubit(auth)),
      ],
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<RegisterCubit>().submit(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
        );
  }

  void _goToLogin() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.go(
      from == null
          ? AppRoutes.login
          : Uri(
              path: AppRoutes.login,
              queryParameters: {'from': from},
            ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<RegisterCubit, SubmitState<SignUpOutcome>>(
      builder: (context, state) {
        // With email confirmation enabled no session exists yet; when it's
        // disabled the session listener routes the user in automatically.
        if (state.result == SignUpOutcome.confirmationRequired) {
          return _CheckInboxView(
            email: _email.text.trim(),
            onBackToSignIn: _goToLogin,
          );
        }

        final failure = state.status == SubmitStatus.failure ? state.failure : null;
        return AuthScaffold(
          title: l10n.registerTitle,
          subtitle: l10n.registerSubtitle,
          footer: AuthFooterLink(
            question: l10n.registerHaveAccount,
            action: l10n.registerSignIn,
            onTap: _goToLogin,
          ),
          child: AutofillGroup(
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
                    controller: _name,
                    label: l10n.authFullNameLabel,
                    hint: l10n.authFullNameHint,
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    maxLength: Validators.maxNameLength,
                    validator: localizedValidator(context, Validators.fullName),
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _email,
                    label: l10n.authEmailLabel,
                    hint: l10n.authEmailHint,
                    prefixIcon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: localizedValidator(context, Validators.email),
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _password,
                    label: l10n.authPasswordLabel,
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
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    validator: localizedValidator(
                      context,
                      (v) => Validators.confirmPassword(v, _password.text),
                    ),
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.registerButton,
                    loading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckInboxView extends StatelessWidget {
  const _CheckInboxView({required this.email, required this.onBackToSignIn});

  final String email;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ResendConfirmationCubit, SubmitState<void>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) context.showSnack(l10n.registerEmailResent);
        if (state.status == SubmitStatus.failure) context.showSnack(state.failure!.message(l10n));
      },
      builder: (context, resend) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StatusView(
                  icon: Icons.mark_email_unread_outlined,
                  title: l10n.registerCheckInboxTitle,
                  message: l10n.registerCheckInboxBody(email),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.formMaxWidth,
                  ),
                  child: Column(
                    children: [
                      ResendCooldownButton(
                        loading: resend.isSubmitting,
                        onPressed: () async {
                          final cubit = context.read<ResendConfirmationCubit>();
                          await cubit.submit(email);
                          return cubit.state.status == SubmitStatus.success;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: l10n.registerBackToSignIn,
                        onPressed: onBackToSignIn,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
