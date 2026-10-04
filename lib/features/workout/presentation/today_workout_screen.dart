import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/app_api.dart';
import '../../home/state/today_workout_override.dart';
import '../state/active_workout_session.dart';
import 'rest_timer_screen.dart';
import 'widgets/exercise_video_sheet.dart';

class TodayWorkoutScreen extends ConsumerWidget {
  const TodayWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(effectiveTodayWorkoutProvider);
    final lastWorkoutAsync = ref.watch(lastWorkoutProvider);
    final session = ref.watch(activeWorkoutSessionProvider);

    final lastWeights = <String, String>{};
    final lastWorkout = lastWorkoutAsync.asData?.value;
    if (lastWorkout != null) {
      for (final ex in lastWorkout.exercises) {
        if (ex.weight != null) lastWeights[ex.name.trim().toLowerCase()] = ex.weight!;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Treino de Hoje')),
      body: todayAsync.when(
        data: (today) {
          if (today.isRest) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Hoje é dia de descanso. 😴', textAlign: TextAlign.center),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(today.dayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (today.focusLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(today.focusLabel, style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              if (today.exercises.isEmpty) const Text('Nenhum exercício encontrado para hoje.'),
              for (final ex in today.exercises)
                _ExerciseCard(exercise: ex, lastWeight: lastWeights[ex.nome.trim().toLowerCase()], dayName: today.dayName),
              if (session != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Finalizar treino', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Finalizar treino'),
                          content: const Text('Tem certeza que deseja encerrar o treino de hoje?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Finalizar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        ref.read(activeWorkoutSessionProvider.notifier).state = null;
                        context.pop();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Não foi possível carregar o treino de hoje.')),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.exercise, this.lastWeight, this.dayName});

  final WorkoutExercise exercise;
  final String? lastWeight;
  final String? dayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSeconds = parseRestSeconds(exercise.descanso);
    final totalSets = parseSetsCount(exercise.series);
    final timerState = ref.watch(restTimerProvider((exercise.nome, totalSeconds, totalSets)));
    final finished = timerState.finished;
    final inProgress = !finished && timerState.completedSets > 0;

    Color? cardColor;
    if (finished) {
      cardColor = const Color(0xFFE8F5E9);
    } else if (inProgress) {
      cardColor = const Color(0xFFFFF3E0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(exercise.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (finished)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text('Concluído', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else if (inProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${timerState.completedSets}/$totalSets séries',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (exercise.series != null) _Stat('Séries', exercise.series!),
                if (exercise.repeticoes != null) _Stat('Repetições', exercise.repeticoes!),
                if (exercise.descanso != null) _Stat('Descanso', exercise.descanso!),
                if (lastWeight != null) _Stat('Último peso', lastWeight!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: finished
                      ? Icons.check_circle
                      : inProgress
                          ? Icons.replay_circle_filled
                          : Icons.play_circle_fill,
                  label: finished ? 'Feito' : inProgress ? 'Continuar' : 'Iniciar',
                  color: finished ? Colors.green : const Color(0xFFFF6B35),
                  onPressed: () => context.push(
                    '/workout/rest-timer',
                    extra: RestTimerArgs(exercise: exercise, lastWeight: lastWeight, dayName: dayName),
                  ),
                ),
                _ActionButton(
                  icon: Icons.search,
                  label: 'Vídeos',
                  color: const Color(0xFF2196F3),
                  onPressed: () => showExerciseVideoSheet(context, exerciseName: exercise.nome),
                ),
                _ActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Trocar',
                  color: const Color(0xFF42A5F5),
                  onPressed: () => context.push('/coming-soon/trocar-exercicio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
