import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/l10n.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

final _brDateFormat = DateFormat('dd/MM/yyyy');

class NameStep extends ConsumerStatefulWidget {
  const NameStep({super.key});

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final _controller = TextEditingController(text: ref.read(onboardingControllerProvider).name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return StepScaffold(
      title: context.l10n.onboardingNameTitle,
      error: state.fieldErrors['name'],
      buttonLabel: context.l10n.continuar,
      onContinue: () {
        if (_controller.text.trim().isEmpty) return;
        controller.setName(_controller.text.trim());
      },
      child: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: context.l10n.onboardingNameHint),
      ),
    );
  }
}

class GenderStep extends ConsumerWidget {
  const GenderStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    return StepScaffold(
      title: l.onboardingGenderTitle,
      error: state.fieldErrors['gender'],
      onBack: () => controller.goTo(OnboardingStep.disclaimer),
      child: ChoiceList(
        selected: state.gender,
        options: [MapEntry('Masculino', l.genderMale), MapEntry('Feminino', l.genderFemale)],
        onSelected: controller.setGender,
      ),
    );
  }
}

class BirthDateStep extends ConsumerWidget {
  const BirthDateStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    return StepScaffold(
      title: l.onboardingBirthDateTitle,
      error: state.fieldErrors['birthDate'],
      onBack: () => controller.goTo(OnboardingStep.gender),
      buttonLabel: state.birthDate != null ? l.continuar : null,
      onContinue: state.birthDate != null ? controller.confirmBirthDate : null,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: state.birthDate ?? DateTime(now.year - 30),
            firstDate: DateTime(now.year - 100),
            lastDate: now,
          );
          if (picked != null) {
            controller.pickBirthDate(picked);
          }
        },
        child: Text(state.birthDate != null ? _brDateFormat.format(state.birthDate!) : l.onboardingPickDate),
      ),
    );
  }
}

class WeightStep extends ConsumerStatefulWidget {
  const WeightStep({super.key});

  @override
  ConsumerState<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends ConsumerState<WeightStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return StepScaffold(
      title: context.l10n.onboardingWeightTitle,
      error: state.fieldErrors['weight'],
      onBack: () => controller.goTo(OnboardingStep.birthDate),
      buttonLabel: context.l10n.continuar,
      onContinue: () {
        final value = double.tryParse(_controller.text.replaceAll(',', '.'));
        if (value != null) controller.setWeight(value);
      },
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(hintText: context.l10n.onboardingWeightHint),
      ),
    );
  }
}

class HeightStep extends ConsumerStatefulWidget {
  const HeightStep({super.key});

  @override
  ConsumerState<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends ConsumerState<HeightStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    return StepScaffold(
      title: context.l10n.onboardingHeightTitle,
      error: state.fieldErrors['height'],
      onBack: () => controller.goTo(OnboardingStep.weight),
      buttonLabel: context.l10n.continuar,
      onContinue: () {
        final value = double.tryParse(_controller.text.replaceAll(',', '.'));
        if (value != null) controller.setHeight(value);
      },
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(hintText: context.l10n.onboardingHeightHint),
      ),
    );
  }
}

class ProfileConfirmationStep extends ConsumerWidget {
  const ProfileConfirmationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    return StepScaffold(
      title: l.onboardingConfirmDataTitle,
      onBack: () => controller.goTo(OnboardingStep.height),
      loading: state.loading,
      error: state.error,
      buttonLabel: l.confirmar,
      onContinue: () => controller.submitProfile(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(l.summaryName, state.name),
          _SummaryRow(l.summaryCpf, state.cpf),
          _SummaryRow(l.summaryTerms, state.disclaimerAccepted ? l.summaryAccepted : l.summaryNotAccepted),
          _SummaryRow(l.summaryGender, state.gender ?? ''),
          _SummaryRow(l.summaryBirthDate, state.birthDate != null ? _brDateFormat.format(state.birthDate!) : ''),
          _SummaryRow(l.summaryWeight, state.weight != null ? l.unitKg('${state.weight}') : ''),
          _SummaryRow(l.summaryHeight, state.height != null ? l.unitCm('${state.height}') : ''),
          _SummaryRow(l.summaryEmail, state.email),
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
