import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      title: 'Qual é o seu nome completo?',
      error: state.fieldErrors['name'],
      buttonLabel: 'Continuar',
      onContinue: () {
        if (_controller.text.trim().isEmpty) return;
        controller.setName(_controller.text.trim());
      },
      child: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Nome e sobrenome'),
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
    return StepScaffold(
      title: 'Qual o seu gênero?',
      error: state.fieldErrors['gender'],
      onBack: () => controller.goTo(OnboardingStep.disclaimer),
      child: ChoiceList(
        selected: state.gender,
        options: const [MapEntry('Masculino', 'Masculino'), MapEntry('Feminino', 'Feminino')],
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
    return StepScaffold(
      title: 'Qual a sua data de nascimento?',
      error: state.fieldErrors['birthDate'],
      onBack: () => controller.goTo(OnboardingStep.gender),
      buttonLabel: state.birthDate != null ? 'Continuar' : null,
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
        child: Text(state.birthDate != null ? _brDateFormat.format(state.birthDate!) : 'Selecionar data'),
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
      title: 'Qual o seu peso? (kg)',
      error: state.fieldErrors['weight'],
      onBack: () => controller.goTo(OnboardingStep.birthDate),
      buttonLabel: 'Continuar',
      onContinue: () {
        final value = double.tryParse(_controller.text.replaceAll(',', '.'));
        if (value != null) controller.setWeight(value);
      },
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(hintText: 'Ex: 70.5'),
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
      title: 'Qual a sua altura? (cm)',
      error: state.fieldErrors['height'],
      onBack: () => controller.goTo(OnboardingStep.weight),
      buttonLabel: 'Continuar',
      onContinue: () {
        final value = double.tryParse(_controller.text.replaceAll(',', '.'));
        if (value != null) controller.setHeight(value);
      },
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(hintText: 'Ex: 175'),
      ),
    );
  }
}

class EmailStep extends ConsumerStatefulWidget {
  const EmailStep({super.key});

  @override
  ConsumerState<EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<EmailStep> {
  late final _controller = TextEditingController(text: ref.read(onboardingControllerProvider).email);

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
      title: 'Qual o seu email?',
      error: state.fieldErrors['email'],
      onBack: () => controller.goTo(OnboardingStep.height),
      buttonLabel: 'Continuar',
      onContinue: () {
        if (_controller.text.trim().isEmpty) return;
        controller.setEmail(_controller.text.trim());
      },
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(hintText: 'seuemail@exemplo.com'),
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
    return StepScaffold(
      title: 'Confira seus dados',
      onBack: () => controller.goTo(OnboardingStep.password),
      loading: state.loading,
      error: state.error,
      buttonLabel: 'Confirmar',
      onContinue: () => controller.submitProfile(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow('Nome', state.name),
          _SummaryRow('CPF', state.cpf),
          _SummaryRow('Termos de uso', state.disclaimerAccepted ? 'Aceito' : 'Não aceito'),
          _SummaryRow('Gênero', state.gender ?? ''),
          _SummaryRow('Data de nascimento', state.birthDate != null ? _brDateFormat.format(state.birthDate!) : ''),
          _SummaryRow('Peso', '${state.weight ?? ''} kg'),
          _SummaryRow('Altura', '${state.height ?? ''} cm'),
          _SummaryRow('Email', state.email),
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
