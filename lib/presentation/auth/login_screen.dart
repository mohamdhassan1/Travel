import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/inline_message.dart';
import '../../data/repositories/auth_repository.dart';
import '../../logic/auth/auth_form_cubits.dart';
import '../../logic/auth/session_cubit.dart';
import '../../routing/app_routes.dart';
import '../common/l10n_extensions.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginCubit(auth)),
        BlocProvider(create: (_) => ResendConfirmationCubit(auth)),
      ],
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final bool _sessionEnded;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>();
    _sessionEnded = session.state.endedUnexpectedly;
    if (_sessionEnded) session.acknowledgeSessionEnded();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginCubit>().submit(
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Preserve the deep-link target across auth screens.
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    String withFrom(String path) => from == null ? path : Uri(path: path, queryParameters: {'from': from}).toString();

    return BlocListener<ResendConfirmationCubit, SubmitState<void>>(
      listener: (context, state) {
        if (state.status == SubmitStatus.success) context.showSnack(l10n.loginConfirmationResent);
        if (state.status == SubmitStatus.failure) context.showSnack(state.failure!.message(l10n));
      },
      child: AuthScaffold(
        title: l10n.loginTitle,
        subtitle: l10n.loginSubtitle,
        footer: AuthFooterLink(
          question: l10n.loginNoAccount,
          action: l10n.loginCreateAccount,
          onTap: () => context.go(withFrom(AppRoutes.register)),
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: BlocBuilder<LoginCubit, SubmitState<void>>(
              builder: (context, state) {
                final failure = state.status == SubmitStatus.failure ? state.failure : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_sessionEnded && failure == null) ...[
                      InlineMessage(
                        message: l10n.sessionEndedBanner,
                        tone: InlineMessageTone.info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (failure != null) ...[
                      InlineMessage(
                        message: failure.message(l10n),
                        action: failure.type == FailureType.emailNotConfirmed
                            ? BlocBuilder<ResendConfirmationCubit, SubmitState<void>>(
                                builder: (context, resend) => TextButton(
                                  onPressed: resend.isSubmitting
                                      ? null
                                      : () => context.read<ResendConfirmationCubit>().submit(_email.text),
                                  child: Text(l10n.loginResendConfirmation),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppTextField(
                      controller: _email,
                      label: l10n.authEmailLabel,
                      hint: l10n.authEmailHint,
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      validator: localizedValidator(context, Validators.email),
                      enabled: !state.isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _password,
                      label: l10n.authPasswordLabel,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      showPasswordLabel: l10n.authShowPassword,
                      hidePasswordLabel: l10n.authHidePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      validator: localizedValidator(
                        context,
                        Validators.loginPassword,
                      ),
                      enabled: !state.isSubmitting,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: state.isSubmitting ? null : () => context.push(AppRoutes.forgotPassword),
                        child: Text(l10n.loginForgotPassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: l10n.loginButton,
                      loading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
