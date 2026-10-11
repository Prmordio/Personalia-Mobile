import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

class DurationRangeStep extends ConsumerWidget {
  const DurationRangeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    final min = state.minTrainingDuration ?? 45;
    final max = state.maxTrainingDuration ?? 60;
    return StepScaffold(
      title: l.onboardingDurationTitle,
      subtitle: l.onboardingDurationSubtitle,
      onBack: () => controller.goTo(OnboardingStep.anamnesisConfirmation),
      error: state.fieldErrors['minTrainingDuration'] ?? state.fieldErrors['maxTrainingDuration'],
      buttonLabel: l.continuar,
      onContinue: controller.confirmDurationRange,
      child: Column(
        children: [
          Text(l.onboardingDurationMin, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          NumberSpinner(value: min, min: 30, max: 180, step: 5, onChanged: controller.setMinDurationDraft),
          const SizedBox(height: 32),
          Text(l.onboardingDurationMax, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          NumberSpinner(value: max, min: 30, max: 180, step: 5, onChanged: controller.setMaxDurationDraft),
        ],
      ),
    );
  }
}

class TrainingDaysStep extends ConsumerWidget {
  const TrainingDaysStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    final days = state.trainingDaysPerWeek ?? 3;
    return StepScaffold(
      title: l.onboardingTrainingDaysTitle,
      subtitle: l.onboardingTrainingDaysSubtitle,
      onBack: () => controller.goTo(OnboardingStep.trainingDuration),
      error: state.fieldErrors['trainingDaysPerWeek'],
      buttonLabel: l.continuar,
      onContinue: controller.confirmTrainingDays,
      child: NumberSpinner(value: days, min: 1, max: 7, onChanged: controller.setTrainingDaysDraft, suffix: ' ${l.suffixDays(days)}'),
    );
  }
}

class GymTimeStep extends ConsumerStatefulWidget {
  const GymTimeStep({super.key});

  @override
  ConsumerState<GymTimeStep> createState() => _GymTimeStepState();
}

class _GymTimeStepState extends ConsumerState<GymTimeStep> {
  late final _hourController = TextEditingController(text: _initialPart(0));
  late final _minuteController = TextEditingController(text: _initialPart(1));

  String _initialPart(int index) {
    final time = ref.read(onboardingControllerProvider).preferredGymTime;
    if (time == null) return '';
    final parts = time.split(':');
    return parts.length == 2 ? parts[index] : '';
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _syncTime(OnboardingController controller) {
    final hour = int.tryParse(_hourController.text);
    final minute = int.tryParse(_minuteController.text);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      controller.pickGymTime('');
      return;
    }
    controller.pickGymTime('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    final hasValidTime = (state.preferredGymTime ?? '').isNotEmpty;
    return StepScaffold(
      title: l.onboardingGymTimeTitle,
      subtitle: l.onboardingGymTimeSubtitle,
      onBack: () => controller.goTo(OnboardingStep.trainingDays),
      error: state.fieldErrors['preferredGymTime'],
      buttonLabel: hasValidTime ? l.continuar : null,
      onContinue: hasValidTime ? controller.confirmGymTime : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _hourController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'HH', counterText: ''),
                  onChanged: (_) => _syncTime(controller),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _minuteController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'MM', counterText: ''),
                  onChanged: (_) => _syncTime(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: controller.skipGymTime,
            child: Text(l.pular),
          ),
        ],
      ),
    );
  }
}

class CardioStep extends ConsumerWidget {
  const CardioStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.watch(onboardingControllerProvider);
    return StepScaffold(
      title: context.l10n.onboardingCardioTitle,
      onBack: () => controller.goTo(OnboardingStep.gymTime),
      child: YesNoChoice(value: state.wantsCardio, onChanged: controller.setWantsCardio),
    );
  }
}

class TrainingFocusStep extends ConsumerWidget {
  const TrainingFocusStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    final options = [
      MapEntry('superior', l.focusUpper),
      MapEntry('inferior', l.focusLower),
      MapEntry('corpo_todo', l.focusFullBody),
    ];
    return StepScaffold(
      title: l.onboardingTrainingFocusTitle,
      onBack: () => controller.goTo(OnboardingStep.cardio),
      loading: state.loading,
      error: state.error ?? state.fieldErrors['trainingFocus'],
      child: ChoiceList(
        options: options,
        selected: state.trainingFocus,
        onSelected: (value) {
          controller.setTrainingFocus(value);
          controller.submitTrainingPreferences();
        },
      ),
    );
  }
}
