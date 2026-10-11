import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/app_api.dart';
import 'widgets/exercise_list.dart';
import 'widgets/exercise_thumbnail.dart';

class CurrentWorkoutScreen extends ConsumerWidget {
  const CurrentWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(currentWorkoutProvider);

    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.currentWorkoutTitle)),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return Center(child: Text(l.currentWorkoutNoWorkout));
          }
          final trainingDays = workout.days
              .where((d) => d.exercises.isNotEmpty)
              .length;
          final totalExercises = workout.days.fold<int>(
            0,
            (sum, d) => sum + d.exercises.length,
          );
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(currentWorkoutProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.blue,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.currentWorkoutPlanLabel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workout.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.currentWorkoutDaysExercises(trainingDays, totalExercises),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final day in workout.days) _DayCard(day: day),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l.errLoadCurrentWorkout)),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});
  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    final preview = day.exercises.take(4).toList();
    final hasCardio = day.exercises.any(isCardioExercise);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/workout/day', extra: day),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      day.dayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                day.exercises.isEmpty
                    ? context.l10n.dayRecovery
                    : hasCardio
                        ? context.l10n.exercisesCountWithCardio(day.exercises.length)
                        : context.l10n.exercisesCountLabel(day.exercises.length),
                style: const TextStyle(color: Colors.grey),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final ex in preview) ...[
                      ExerciseThumbnail(
                        exerciseName: ex.nome,
                        size: 52,
                        isCardio: isCardioExercise(ex),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (day.exercises.length > preview.length)
                      Text(
                        '+${day.exercises.length - preview.length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview.map((e) => e.nome).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
