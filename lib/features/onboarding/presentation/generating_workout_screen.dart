import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../state/onboarding_controller.dart';

/// Tela final da wizard — dispara a geração do treino (via submitTrainingPreferences ->
/// _startGenerating) e mostra o progresso enquanto o OnboardingController faz polling.
/// Geração pode falhar por falta de assinatura ativa (mesma regra do botão manual da Home);
/// nesse caso, o fallback "Ir para o início" leva pro mesmo botão manual.
class GeneratingWorkoutScreen extends ConsumerWidget {
  const GeneratingWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);

    if (state.step == OnboardingStep.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!state.generationTimedOut) ...[
                const _AiThinkingIndicator(),
                const SizedBox(height: 8),
                const Text(
                  'Isso pode levar alguns minutos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                const Icon(Icons.access_time, size: 48, color: AppColors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Isso está demorando mais que o normal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Você pode continuar pelo início — seu treino aparece por lá assim que ficar pronto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Ir para o início'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _thinkingSteps = [
  ('🤔', 'Analisando seu perfil...'),
  ('🧠', 'Pensando no melhor plano...'),
  ('📊', 'Calculando séries e cargas...'),
  ('🏋️', 'Escolhendo os exercícios certos...'),
  ('⚙️', 'Ajustando o volume de treino...'),
  ('💪', 'Alinhando com o seu objetivo...'),
  ('✨', 'Finalizando os detalhes...'),
];

/// Emoji + frase giram juntos, tipo "IA pensando" — só cosmético, não reflete progresso
/// real (não temos telemetria do agente aqui), só ilustra que algo está acontecendo.
class _AiThinkingIndicator extends StatefulWidget {
  const _AiThinkingIndicator();

  @override
  State<_AiThinkingIndicator> createState() => _AiThinkingIndicatorState();
}

class _AiThinkingIndicatorState extends State<_AiThinkingIndicator> {
  int _index = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      setState(() => _index = (_index + 1) % _thinkingSteps.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, label) = _thinkingSteps[_index];
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Text(emoji, key: ValueKey(emoji), style: const TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            label,
            key: ValueKey(label),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
