import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../state/forgot_password_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
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
                  onPressed: state.loading ? null : () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Redefinir senha', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                onCodeStep
                    ? 'Digite o código que chegou no seu email e escolha uma nova senha.'
                    : 'Informe o email da sua conta. Vamos enviar um código para você criar uma nova senha.',
              ),
              const SizedBox(height: 24),
              if (!onCodeStep)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'seuemail@exemplo.com'),
                ),
              if (onCodeStep) ...[
                if (state.info != null) ...[
                  Text(state.info!),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Código de 6 dígitos', counterText: ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(hintText: 'Nova senha (mínimo 8 caracteres)'),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(state.error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.loading
                    ? null
                    : () => onCodeStep
                        ? controller.resetPassword(_codeController.text.trim(), _passwordController.text)
                        : controller.requestCode(_emailController.text.trim()),
                child: state.loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(onCodeStep ? 'Salvar nova senha' : 'Enviar código'),
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
                  child: const Text('Não recebi o código / trocar email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
