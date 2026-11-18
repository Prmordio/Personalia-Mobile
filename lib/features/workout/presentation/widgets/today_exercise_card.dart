import '../../../../core/l10n/l10n.dart';
import '../../../home/data/app_api.dart';
import '../../data/exercise_image_provider.dart';
import '../../state/rest_timer_controller.dart';
import '../../state/workout_live_activity.dart';
import '../../state/workout_session_cache.dart';
import 'exercise_video_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_action_button.dart';

/// Card de um exercício do treino de hoje: status do cronômetro, última carga e ações.
class TodayExerciseCard extends ConsumerWidget {
  const TodayExerciseCard({
    super.key,
    required this.exercise,
    required this.effectiveExercise,
    required this.isSwapped,
    this.lastWeight,
    this.lastObservation,
    this.dayName,
    required this.onSwap,
    required this.onStart,
  });

  final WorkoutExercise exercise;
  final WorkoutExercise effectiveExercise;
  final bool isSwapped;
  final String? lastWeight;
  final String? lastObservation;
  final String? dayName;
  final VoidCallback onSwap;
  final void Function(
    WorkoutExercise effective,
    String? lastWeight,
    String? lastObservation,
    String? dayName,
  )
  onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerKey = restTimerKeyFor(effectiveExercise);
    final (_, totalSeconds, totalSets) = timerKey;
    final timerState = ref.watch(restTimerProvider(timerKey));
    final finished = timerState.finished;
    final inProgress = !finished && timerState.completedSets > 0;
    final isCardio =
        effectiveExercise.modeloDeTreino?.toLowerCase() == 'cardio';
    final imageBytes = ref
        .watch(exerciseImageProvider(effectiveExercise.nome))
        .asData
        ?.value;

    Color? cardColor;
    if (finished) {
      cardColor = Theme.of(context).brightness == Brightness.dark
          ? Color.alphaBlend(
              Colors.green.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.surfaceContainer,
            )
          : const Color(0xFFE8F5E9);
    } else if (inProgress) {
      cardColor = const Color(0xFFFFF3E0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            onStart(effectiveExercise, lastWeight, lastObservation, dayName),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    effectiveExercise.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isSwapped)
                                    Text(
                                      context.l10n.exerciseSwapped(
                                        exercise.nome,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (finished)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      context.l10n.exerciseCompleted,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (inProgress)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCardio
                                      ? context.l10n.exerciseRunning
                                      : context.l10n.exerciseSetsProgress(
                                          timerState.completedSets,
                                          totalSets,
                                        ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            if (isCardio) ...[
                              if (effectiveExercise.repeticoes != null)
                                WorkoutStat(
                                  context.l10n.statGoal,
                                  effectiveExercise.repeticoes!,
                                ),
                              if (finished)
                                WorkoutStat(context.l10n.statTime, timerState.weight),
                              WorkoutStat(
                                context.l10n.statLastTime,
                                lastWeight ?? '—',
                              ),
                            ] else ...[
                              if (effectiveExercise.series != null)
                                WorkoutStat(
                                  context.l10n.statSets,
                                  effectiveExercise.series!,
                                ),
                              if (effectiveExercise.repeticoes != null)
                                WorkoutStat(
                                  context.l10n.statReps,
                                  effectiveExercise.repeticoes!,
                                ),
                              if (effectiveExercise.descanso != null)
                                WorkoutStat(
                                  context.l10n.statRest,
                                  effectiveExercise.descanso!,
                                ),
                              WorkoutStat(
                                context.l10n.statLastWeight,
                                lastWeight != null ? '$lastWeight kg' : '—',
                              ),
                              if (lastObservation != null &&
                                  lastObservation!.isNotEmpty)
                                WorkoutStat(
                                  context.l10n.statLastObs,
                                  lastObservation!,
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (imageBytes != null) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Only Vídeos (blue) and Trocar (orange) — card tap handles starting
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  if (finished) ...[
                    WorkoutActionButton(
                      icon: Icons.edit_outlined,
                      label: context.l10n.editExerciseLabel,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => onStart(
                        effectiveExercise,
                        lastWeight,
                        lastObservation,
                        dayName,
                      ),
                    ),
                    WorkoutActionButton(
                      icon: Icons.delete_outline,
                      label: context.l10n.cancelCompletedExerciseLabel,
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () async {
                        final l = context.l10n;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l.cancelCompletedExerciseLabel),
                            content: Text(l.cancelCompletedExerciseMessage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l.cancelar),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l.sim),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        final cache = ref.read(workoutSessionCacheProvider);
                        try {
                          await cache.ignoreNative(effectiveExercise.nome);
                          ref
                              .read(
                                restTimerProvider(timerKey).notifier,
                              )
                              .resetForNewSession();
                          await cache.flush();
                          await ref
                              .read(workoutLiveProvider.notifier)
                              .resetCompleted(effectiveExercise.nome);
                          await cache.allowNative(effectiveExercise.nome);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.genericError)),
                            );
                          }
                        }
                      },
                    ),
                  ],
                  WorkoutActionButton(
                    icon: Icons.search,
                    label: context.l10n.btnVideos,
                    color: const Color(0xFF2196F3),
                    onPressed: () => showExerciseVideoSheet(
                      context,
                      exerciseName: effectiveExercise.nome,
                    ),
                  ),
                  WorkoutActionButton(
                    icon: Icons.swap_horiz,
                    label: context.l10n.btnSwap,
                    color: const Color(0xFFFF6B35),
                    onPressed: finished ? null : onSwap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
