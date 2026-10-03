import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/password_text_field.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

class CreatePasswordStep extends ConsumerStatefulWidget {
  const CreatePasswordStep({super.key});

  @override
  ConsumerState<CreatePasswordStep> createState() => _CreatePasswordStepState();
}

class _CreatePasswordStepState extends ConsumerState<CreatePasswordStep> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return StepScaffold(
      title: 'Crie uma senha',
      subtitle: 'Assim você também pode entrar com email e senha, sem precisar de um novo código toda vez.',
      onBack: () => controller.goTo(OnboardingStep.email),
      error: _localError ?? state.fieldErrors['password'],
      buttonLabel: 'Continuar',
      onContinue: () {
        if (_passwordController.text != _confirmController.text) {
          setState(() => _localError = 'As senhas não coincidem.');
          return;
        }
        setState(() => _localError = null);
        controller.confirmPassword(_passwordController.text);
      },
      child: Column(
        children: [
          PasswordTextField(
            controller: _passwordController,
            hintText: 'Senha (mínimo 8 caracteres)',
          ),
          const SizedBox(height: 12),
          PasswordTextField(
            controller: _confirmController,
            hintText: 'Confirmar senha',
          ),
        ],
      ),
    );
  }
}
