import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/password_text_field.dart';
import '../state/signup_controller.dart';

/// Cadastro no app: email → código por email → senha + telefone → [código SMS].
/// Se o email é de uma conta do WhatsApp, o telefone dela é obrigatório (traz o histórico).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(signupControllerProvider);
    final controller = ref.read(signupControllerProvider.notifier);

    final (description, buttonLabel, onSubmit) = switch (state.step) {
      SignupStep.email => (
        l.signupEmailDesc,
        l.appAccessSendCodeAction,
        () => controller.requestCode(_emailController.text),
      ),
      SignupStep.code => (
        context.resolveMessage(state.info) ?? '',
        l.appAccessConfirmCode,
        () => controller.verifyCode(_codeController.text.trim()),
      ),
      SignupStep.password => (
        state.linkAccount ? l.signupLinkAccountDesc : l.signupPasswordDesc,
        l.signupCreateAccount,
        () => controller.createAccount(
          password: _passwordController.text,
          confirmation: _confirmationController.text,
          phone: _phoneController.text,
        ),
      ),
      SignupStep.phoneCode => (
        context.resolveMessage(state.info) ?? l.signupPhoneCodeDesc,
        l.appAccessConfirmCode,
        () => controller.verifyPhoneCode(_phoneCodeController.text.trim()),
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    // No passo do SMS, voltar = trocar o número (a conta só é criada no fim).
                    onPressed: state.loading
                        ? null
                        : state.step == SignupStep.phoneCode
                        ? controller.backToPassword
                        : () => context.go('/login'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.signupTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(description),
                const SizedBox(height: 24),
                ...switch (state.step) {
                  SignupStep.email => [
                    TextField(
                      controller: _emailController,
                      onChanged: (_) => controller.editEmail(),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(hintText: l.onboardingEmailHint),
                    ),
                  ],
                  SignupStep.code => [
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(hintText: l.appAccessCodeHint, counterText: ''),
                    ),
                  ],
                  SignupStep.password => [
                    PasswordTextField(
                      controller: _passwordController,
                      hintText: l.onboardingPasswordHint,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 12),
                    PasswordTextField(
                      controller: _confirmationController,
                      hintText: l.appAccessRepeatPasswordHint,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\s-]'))],
                      decoration: InputDecoration(
                        hintText: state.linkAccount ? l.signupLinkPhoneHint : l.signupPhoneOptionalHint,
                        helperText: state.linkAccount ? l.signupLinkPhoneHelp : l.signupPhoneOptionalHelp,
                        helperMaxLines: 2,
                      ),
                    ),
                  ],
                  SignupStep.phoneCode => [
                    TextField(
                      controller: _phoneCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(hintText: l.appAccessCodeHint, counterText: ''),
                    ),
                  ],
                },
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.resolveMessage(state.error)!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                if (state.emailTaken)
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l.signupGoToLogin),
                  )
                else
                  ElevatedButton(
                    onPressed: state.loading ? null : onSubmit,
                    child: state.loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          )
                        : Text(buttonLabel),
                  ),
                if (state.step == SignupStep.code) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: state.loading ? null : controller.resendCode,
                    child: Text(l.loginResendCode),
                  ),
                  TextButton(
                    onPressed: state.loading
                        ? null
                        : () {
                            _codeController.clear();
                            _emailController.text = state.email;
                            controller.restart();
                          },
                    child: Text(l.appAccessNoEmail),
                  ),
                ],
                if (state.step == SignupStep.phoneCode) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: state.loading ? null : controller.sendPhoneCode,
                    child: Text(l.loginResendCode),
                  ),
                  if (!state.linkAccount)
                    TextButton(
                      onPressed: state.loading ? null : controller.skipPhone,
                      child: Text(l.signupPhoneSkip),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
