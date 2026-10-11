import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/password_text_field.dart';
import '../state/forgot_password_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    final onCodeStep = state.step == ForgotPasswordStep.code;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: state.loading
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.forgotPasswordTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                onCodeStep
                    ? context.l10n.forgotPasswordEnterCodeDesc
                    : context.l10n.forgotPasswordEnterEmailDesc,
              ),
              const SizedBox(height: 24),
              if (!onCodeStep)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    hintText: context.l10n.onboardingEmailHint,
                  ),
                ),
              if (onCodeStep) ...[
                if (state.info != null) ...[
                  Text(context.resolveMessage(state.info)!),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: context.l10n.forgotPasswordCodeHint,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                PasswordTextField(
                  controller: _passwordController,
                  hintText: context.l10n.forgotPasswordNewPasswordHint,
                  autofillHints: const [AutofillHints.newPassword],
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.resolveMessage(state.error)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.loading
                    ? null
                    : () => onCodeStep
                          ? controller.resetPassword(
                              _codeController.text.trim(),
                              _passwordController.text,
                            )
                          : controller.requestCode(
                              _emailController.text.trim(),
                            ),
                child: state.loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      )
                    : Text(onCodeStep ? context.l10n.forgotPasswordSavePassword : context.l10n.forgotPasswordSendCode),
              ),
              if (onCodeStep) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.loading
                      ? null
                      : () {
                          _codeController.clear();
                          _emailController.text = state.email;
                          controller.restart();
                        },
                  child: Text(context.l10n.forgotPasswordNoCode),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
