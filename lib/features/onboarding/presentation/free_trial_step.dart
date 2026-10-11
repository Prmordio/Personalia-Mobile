import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

/// Anúncio dos 7 dias grátis — aparece ao fim do onboarding, antes de disparar a geração.
class FreeTrialStep extends ConsumerWidget {
  const FreeTrialStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final nameParts = state.name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty ? nameParts.first : '👋';

    return StepScaffold(
      title: context.l10n.freeTrialTitle(firstName),
      subtitle: context.l10n.freeTrialSubtitle,
      buttonLabel: context.l10n.generateWorkoutButton,
      onContinue: controller.proceedToGenerate,
      child: const SizedBox.shrink(),
    );
  }
}
