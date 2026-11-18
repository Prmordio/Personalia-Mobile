import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../core/widgets/emoji_loader.dart';
import '../../data/app_api.dart';
import '../../state/workout_generation_controller.dart';
import '../subscription_checkout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoWorkoutCard extends ConsumerWidget {
  const NoWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(workoutGenerationProvider);
    final controller = ref.read(workoutGenerationProvider.notifier);

    Future<void> generate() async {
      final locale = ref.read(localeProvider);
      final language = locale?.languageCode ?? 'pt';
      final outcome = await controller.generate(language: language);
      if (!context.mounted) return;
      switch (outcome) {
        case GenerateOutcome.subscriptionRequired:
          ref.invalidate(subscriptionProvider);
          await showSubscriptionRequiredDialog(context, ref);
        case GenerateOutcome.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errCannotStartGeneration)),
          );
        case GenerateOutcome.started:
        case GenerateOutcome.alreadyRunning:
          break;
      }
    }

    final l = context.l10n;
    final (
      String title,
      String? subtitle,
      String buttonLabel,
      VoidCallback? onPressed,
    ) = switch (status) {
      WorkoutGenerationStatus.idle => (
        l.noWorkoutIdleTitle,
        null,
        l.generateWorkoutButton,
        generate,
      ),
      WorkoutGenerationStatus.requesting => (
        l.noWorkoutIdleTitle,
        null,
        l.btnSendingRequest,
        null,
      ),
      WorkoutGenerationStatus.generating => (
        l.noWorkoutGeneratingTitle,
        l.noWorkoutGeneratingSubtitle,
        l.btnGenerating,
        null,
      ),
      WorkoutGenerationStatus.failed => (
        l.noWorkoutFailedTitle,
        l.noWorkoutFailedSubtitle,
        l.btnRetry,
        generate,
      ),
      WorkoutGenerationStatus.timedOut => (
        l.noWorkoutTimedOutTitle,
        l.noWorkoutTimedOutSubtitle,
        l.btnCheckAgain,
        controller.checkAgain,
      ),
    };
    final busy =
        status == WorkoutGenerationStatus.requesting ||
        status == WorkoutGenerationStatus.generating;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: busy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          // Botão desabilitado é cinza: spinner branco sumiria.
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(buttonLabel),
                      ],
                    )
                  : Text(buttonLabel),
            ),
            if (status == WorkoutGenerationStatus.generating) ...[
              const SizedBox(height: 20),
              const EmojiLoader(),
            ],
          ],
        ),
      ),
    );
  }
}
