import 'package:flutter/material.dart';
import '../../home/data/app_api.dart';
import 'widgets/exercise_list.dart';

class WorkoutDayDetailScreen extends StatelessWidget {
  const WorkoutDayDetailScreen({super.key, required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    final strength = day.exercises.where((e) => !isCardioExercise(e)).toList();
    final totalSets = strength.fold<int>(0, (sum, e) => sum + (int.tryParse(RegExp(r'\d+').stringMatch(e.series ?? '') ?? '') ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(day.dayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (day.exercises.isNotEmpty) ...[
            Row(
              children: [
                _Summary(icon: Icons.fitness_center, value: '${strength.length}', label: 'exercícios'),
                _Summary(icon: Icons.repeat, value: '$totalSets', label: 'séries'),
                if (strength.length != day.exercises.length)
                  const _Summary(icon: Icons.directions_run, value: '✓', label: 'cardio'),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Toque em um exercício para ver vídeos de execução.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
          ],
          ExerciseList(exercises: day.exercises, emptyMessage: 'Dia de recuperação — sem exercícios.'),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
