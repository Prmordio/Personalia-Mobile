import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/app_api.dart';
import '../../home/state/today_workout_override.dart';
import 'rest_timer_screen.dart';
import 'widgets/exercise_video_sheet.dart';

class TodayWorkoutScreen extends ConsumerWidget {
  const TodayWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(effectiveTodayWorkoutProvider);
    final lastWorkoutAsync = ref.watch(lastWorkoutProvider);

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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Não foi possível carregar o treino de hoje.')),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, this.lastWeight, this.dayName});

  final WorkoutExercise exercise;
  final String? lastWeight;
  final String? dayName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (exercise.series != null) _Stat('Séries', exercise.series!),
                if (exercise.repeticoes != null) _Stat('Repetições', exercise.repeticoes!),
                if (exercise.descanso != null) _Stat('Descanso', exercise.descanso!),
                if (lastWeight != null) _Stat('Último peso', '$lastWeight kg'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Iniciar exercício',
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () => context.push(
                    '/workout/rest-timer',
                    extra: RestTimerArgs(exercise: exercise, lastWeight: lastWeight, dayName: dayName),
                  ),
                ),
                IconButton(
                  tooltip: 'Buscar vídeos',
                  icon: const Icon(Icons.search),
                  onPressed: () => showExerciseVideoSheet(context, exerciseName: exercise.nome),
                ),
                IconButton(
                  tooltip: 'Trocar exercício',
                  icon: const Icon(Icons.swap_horiz),
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
