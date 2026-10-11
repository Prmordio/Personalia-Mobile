import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

const _termsUrl = 'https://personalia.fit/legal';

class CpfStep extends ConsumerStatefulWidget {
  const CpfStep({super.key});

  @override
  ConsumerState<CpfStep> createState() => _CpfStepState();
}

class _CpfStepState extends ConsumerState<CpfStep> {
  late final _controller = TextEditingController(text: ref.read(onboardingControllerProvider).cpf);

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
      title: context.l10n.onboardingCpfTitle,
      onBack: () => controller.goTo(OnboardingStep.name),
      error: state.fieldErrors['cpf'],
      buttonLabel: context.l10n.continuar,
      onContinue: () {
        if (_controller.text.trim().isEmpty) return;
        controller.setCpf(_controller.text.trim());
      },
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: context.l10n.onboardingCpfHint),
      ),
    );
  }
}

class DisclaimerStep extends ConsumerWidget {
  const DisclaimerStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l = context.l10n;
    return StepScaffold(
      title: l.disclaimerTitle,
      subtitle: l.disclaimerSubtitle,
      onBack: () => controller.goTo(OnboardingStep.cpf),
      error: state.fieldErrors['accepted'],
      buttonLabel: l.continuar,
      onContinue: state.disclaimerAccepted ? controller.confirmDisclaimer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: state.disclaimerAccepted,
            onChanged: (value) => controller.setDisclaimerAccepted(value ?? false),
            title: Text(l.disclaimerCheckbox),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(_termsUrl), mode: LaunchMode.externalApplication),
            child: Text(l.disclaimerReadTerms, style: const TextStyle(color: AppColors.blue)),
          ),
        ],
      ),
    );
  }
}
