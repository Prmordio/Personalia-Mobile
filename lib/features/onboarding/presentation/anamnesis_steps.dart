import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

class MainGoalStep extends ConsumerWidget {
  const MainGoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    final options = [
      MapEntry('ganho_massa', l.goalMassGain),
      MapEntry('perda_peso', l.goalWeightLoss),
      MapEntry('forca', l.goalStrength),
      MapEntry('condicionamento', l.goalConditioning),
    ];
    return StepScaffold(
      title: l.onboardingMainGoalTitle,
      onBack: () => controller.goTo(OnboardingStep.profileConfirmation),
      error: state.fieldErrors['mainGoal'],
      child: ChoiceList(options: options, selected: state.mainGoal, onSelected: controller.setMainGoal),
    );
  }
}

/// Doenças/condições médicas e limitações físicas numa tela só.
class HealthConditionsStep extends ConsumerStatefulWidget {
  const HealthConditionsStep({super.key});

  @override
  ConsumerState<HealthConditionsStep> createState() => _HealthConditionsStepState();
}

class _HealthConditionsStepState extends ConsumerState<HealthConditionsStep> {
  // Criados no initState, não com `late` preguiçoso: os campos só aparecem quando a resposta é
  // "Sim", e um controller nunca usado seria criado no dispose() — lendo `ref` já descartado.
  late final TextEditingController _diseasesController;
  late final TextEditingController _limitationsController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _diseasesController = TextEditingController(text: state.diseases);
    _limitationsController = TextEditingController(text: state.physicalLimitations);
  }

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
    final l = context.l10n;
    final error = state.fieldErrors['hasDiseases'] ??
        state.fieldErrors['diseases'] ??
        state.fieldErrors['hasLimitations'] ??
        state.fieldErrors['limitations'];
    return StepScaffold(
      title: l.onboardingHealthTitle,
      onBack: () => controller.goTo(OnboardingStep.mainGoal),
      error: error,
      buttonLabel: l.continuar,
      onContinue: controller.confirmHealthConditions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.onboardingHasDiseases, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          YesNoChoice(value: state.hasDiseases, onChanged: controller.setHasDiseases),
          if (state.hasDiseases == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _diseasesController,
              maxLines: 3,
              decoration: InputDecoration(hintText: l.onboardingDiseasesHint),
              onChanged: controller.setDiseases,
            ),
          ],
          const SizedBox(height: 28),
          Text(l.onboardingHasLimitations, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          YesNoChoice(value: state.hasPhysicalLimitations, onChanged: controller.setHasLimitations),
          if (state.hasPhysicalLimitations == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _limitationsController,
              maxLines: 3,
              decoration: InputDecoration(hintText: l.onboardingLimitationsHint),
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
    final l = context.l10n;
    final options = [
      MapEntry('sedentario', l.activitySedentary),
      MapEntry('leve', l.activityLight),
      MapEntry('moderado', l.activityModerate),
      MapEntry('intenso', l.activityIntense),
      MapEntry('atleta', l.activityAthlete),
    ];
    return StepScaffold(
      title: l.onboardingActivityLevelTitle,
      onBack: () => controller.goTo(OnboardingStep.healthConditions),
      error: state.fieldErrors['physicalActivityLevel'],
      child: ChoiceList(
        options: options,
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
    final l = context.l10n;

    final goalOptions = [
      MapEntry('ganho_massa', l.goalMassGain),
      MapEntry('perda_peso', l.goalWeightLoss),
      MapEntry('forca', l.goalStrength),
      MapEntry('condicionamento', l.goalConditioning),
    ];
    final activityOptions = [
      MapEntry('sedentario', l.activitySedentary),
      MapEntry('leve', l.activityLight),
      MapEntry('moderado', l.activityModerate),
      MapEntry('intenso', l.activityIntense),
      MapEntry('atleta', l.activityAthlete),
    ];

    final goalLabel = goalOptions.firstWhere((o) => o.key == state.mainGoal, orElse: () => const MapEntry('', '')).value;
    final activityLabel = activityOptions.firstWhere((o) => o.key == state.physicalActivityLevel, orElse: () => const MapEntry('', '')).value;

    return StepScaffold(
      title: l.onboardingConfirmAnamnesisTitle,
      onBack: () => controller.goTo(OnboardingStep.activityLevel),
      loading: state.loading,
      error: state.error,
      buttonLabel: l.confirmar,
      onContinue: () => controller.submitAnamnesis(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(l.summaryGoal, goalLabel),
          _SummaryRow(l.summaryDiseases, state.hasDiseases == true ? state.diseases : l.nao),
          _SummaryRow(l.summaryPhysicalLimitations, state.hasPhysicalLimitations == true ? state.physicalLimitations : l.nao),
          _SummaryRow(l.summaryActivityLevel, activityLabel),
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
