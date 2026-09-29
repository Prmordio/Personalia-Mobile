import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/data/app_api.dart';
import 'exercise_thumbnail.dart';
import 'exercise_video_sheet.dart';

final _cardioPattern = RegExp(r'esteira|bike|bicicleta|caminhada|el[ií]ptico|escada|remo erg|cardio|corrida', caseSensitive: false);

bool isCardioExercise(WorkoutExercise ex) =>
    _cardioPattern.hasMatch(ex.nome) || (ex.repeticoes ?? '').toLowerCase().contains('min');

/// Exercícios do dia em cards: foto do aparelho (quando existe na base), séries × repetições,
/// descanso e método. Tocar abre os vídeos de execução.
class ExerciseList extends StatelessWidget {
  const ExerciseList({super.key, required this.exercises, this.emptyMessage = 'Nenhum exercício.'});

  final List<WorkoutExercise> exercises;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Padding(padding: const EdgeInsets.all(16), child: Text(emptyMessage));
    }
    return Column(
      children: [
        for (var i = 0; i < exercises.length; i++) ExerciseCard(index: i + 1, exercise: exercises[i]),
      ],
    );
  }
}

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.index, required this.exercise});

  final int index;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final cardio = isCardioExercise(exercise);
    final volume = cardio
        ? exercise.repeticoes
        : [exercise.series, exercise.repeticoes].whereType<String>().where((s) => s.isNotEmpty).join(' × ');
    final method = exercise.modeloDeTreino;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showExerciseVideoSheet(context, exerciseName: exercise.nome),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ExerciseThumbnail(exerciseName: exercise.nome, isCardio: cardio),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(8)),
                      child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (volume != null && volume.isNotEmpty) _Chip(icon: cardio ? Icons.timer : Icons.repeat, label: volume),
                        if ((exercise.descanso ?? '').isNotEmpty) _Chip(icon: Icons.hourglass_bottom, label: exercise.descanso!),
                        if (method != null && method.isNotEmpty && method.toLowerCase() != 'standard')
                          _Chip(icon: Icons.bolt, label: method),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
