import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

const _mainGoalOptions = [
  MapEntry('ganho_massa', 'Ganho de massa'),
  MapEntry('perda_peso', 'Perda de peso'),
  MapEntry('forca', 'Força'),
  MapEntry('condicionamento', 'Condicionamento'),
];

const _activityLevelOptions = [
  MapEntry('sedentario', 'Sedentário'),
  MapEntry('leve', 'Leve (1-3 dias/semana)'),
  MapEntry('moderado', 'Moderado (3-5 dias/semana)'),
  MapEntry('intenso', 'Intenso (6-7 dias/semana)'),
  MapEntry('atleta', 'Atleta ou trabalho físico pesado'),
];

class MainGoalStep extends ConsumerWidget {
  const MainGoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return StepScaffold(
      title: 'Qual é o seu objetivo principal?',
      onBack: () => controller.goTo(OnboardingStep.profileConfirmation),
      error: state.fieldErrors['mainGoal'],
      child: ChoiceList(options: _mainGoalOptions, selected: state.mainGoal, onSelected: controller.setMainGoal),
    );
  }
}

/// Doenças/condições médicas e limitações físicas numa tela só — cada "Sim" revela um
/// campo de texto inline, em vez de navegar pra uma tela separada.
class HealthConditionsStep extends ConsumerStatefulWidget {
  const HealthConditionsStep({super.key});

  @override
  ConsumerState<HealthConditionsStep> createState() => _HealthConditionsStepState();
}

class _HealthConditionsStepState extends ConsumerState<HealthConditionsStep> {
  late final _diseasesController = TextEditingController(text: ref.read(onboardingControllerProvider).diseases);
  late final _limitationsController =
      TextEditingController(text: ref.read(onboardingControllerProvider).physicalLimitations);

  @override
  void dispose() {
    _diseasesController.dispose();
    _limitationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final error = state.fieldErrors['hasDiseases'] ??
        state.fieldErrors['diseases'] ??
        state.fieldErrors['hasLimitations'] ??
        state.fieldErrors['limitations'];
    return StepScaffold(
      title: 'Saúde e limitações',
      onBack: () => controller.goTo(OnboardingStep.mainGoal),
      error: error,
      buttonLabel: 'Continuar',
      onContinue: controller.confirmHealthConditions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Você possui alguma doença ou condição médica?', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          YesNoChoice(value: state.hasDiseases, onChanged: controller.setHasDiseases),
          if (state.hasDiseases == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _diseasesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Ex: Hipertensão controlada'),
              onChanged: controller.setDiseases,
            ),
          ],
          const SizedBox(height: 28),
          const Text('Você possui alguma limitação física?', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          YesNoChoice(value: state.hasPhysicalLimitations, onChanged: controller.setHasLimitations),
          if (state.hasPhysicalLimitations == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _limitationsController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Ex: Lesão no ombro direito'),
              onChanged: controller.setLimitations,
            ),
          ],
        ],
      ),
    );
  }
}

class ActivityLevelStep extends ConsumerWidget {
  const ActivityLevelStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return StepScaffold(
      title: 'Qual o seu nível de atividade física atual?',
      onBack: () => controller.goTo(OnboardingStep.healthConditions),
      error: state.fieldErrors['physicalActivityLevel'],
      child: ChoiceList(
        options: _activityLevelOptions,
        selected: state.physicalActivityLevel,
        onSelected: controller.setActivityLevel,
      ),
    );
  }
}

class AnamnesisConfirmationStep extends ConsumerWidget {
  const AnamnesisConfirmationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final goalLabel = _mainGoalOptions.firstWhere((o) => o.key == state.mainGoal, orElse: () => const MapEntry('', '')).value;
    final activityLabel =
        _activityLevelOptions.firstWhere((o) => o.key == state.physicalActivityLevel, orElse: () => const MapEntry('', '')).value;
    return StepScaffold(
      title: 'Confira sua anamnese',
      onBack: () => controller.goTo(OnboardingStep.activityLevel),
      loading: state.loading,
      error: state.error,
      buttonLabel: 'Confirmar',
      onContinue: () => controller.submitAnamnesis(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow('Objetivo', goalLabel),
          _SummaryRow('Doenças', state.hasDiseases == true ? state.diseases : 'Não'),
          _SummaryRow('Limitações físicas', state.hasPhysicalLimitations == true ? state.physicalLimitations : 'Não'),
          _SummaryRow('Nível de atividade', activityLabel),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
