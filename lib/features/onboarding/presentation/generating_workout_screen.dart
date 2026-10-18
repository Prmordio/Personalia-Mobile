import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../state/onboarding_controller.dart';

/// Tela final da wizard — mostra animação de "IA pensando" enquanto o OnboardingController
/// faz polling, ou a mensagem de timeout quando o prazo é ultrapassado.
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!state.generationTimedOut) ...[
                const _AiThinkingIndicator(),
                const SizedBox(height: 8),
                Text(
                  context.l10n.generatingWorkoutWait,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ] else ...[
                const Icon(Icons.access_time, size: 48, color: AppColors.orange),
                const SizedBox(height: 16),
                Text(
                  context.l10n.generatingWorkoutTimeout,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.generatingWorkoutTimeoutDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(context.l10n.generatingWorkoutGoHome),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _thinkingEmojis = ['🤔', '🧠', '📊', '🏋️', '⚙️', '💪', '✨'];

/// Emoji + frase giram juntos, cosmético — não reflete progresso real do agente.
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
      setState(() => _index = (_index + 1) % _thinkingEmojis.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _label(AppLocalizations l) {
    return switch (_index) {
      0 => l.thinkingStep0,
      1 => l.thinkingStep1,
      2 => l.thinkingStep2,
      3 => l.thinkingStep3,
      4 => l.thinkingStep4,
      5 => l.thinkingStep5,
      _ => l.thinkingStep6,
    };
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _thinkingEmojis[_index];
    final label = _label(context.l10n);
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
