import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

/// Anúncio dos 7 dias grátis, mesma mensagem/timing do fluxo do WhatsApp
/// (GrantSignupFreeTrialUseCase) — só que aqui é uma tela própria, não uma mensagem de texto,
/// e some antes de disparar a geração de verdade (o backend concede o trial no início de
/// POST /app/workout/generate, se o usuário for elegível).
class FreeTrialStep extends ConsumerWidget {
  const FreeTrialStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final nameParts = state.name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty ? nameParts.first : 'Atleta';

    return StepScaffold(
      title: '🎁 7 dias grátis liberados, $firstName!',
      subtitle: 'Aproveite pra deixar seu treino pronto e explorar o app à vontade.',
      buttonLabel: 'Gerar meu treino',
      onContinue: controller.proceedToGenerate,
      child: const SizedBox.shrink(),
    );
  }
}
