import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

String _kg(num v) => '${(v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1)).replaceAll('.', ',')} kg';

/// Evolução de cargas por exercício (primeira → última, melhor carga).
class LoadEvolutionReportScreen extends StatelessWidget {
  const LoadEvolutionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<List<ExerciseLoad>>(
      title: 'Evolução de cargas',
      provider: loadEvolutionProvider,
      pdf: ReportPdf.workout,
      isEmpty: (exercises) => exercises.isEmpty,
      emptyMessage: 'Registre a carga dos exercícios durante os treinos para acompanhar sua evolução aqui.',
      builder: (context, exercises) {
        final improved = exercises.where((e) => e.change > 0).length;
        return [
          ReportCard(
            title: 'Resumo',
            child: Row(
              children: [
                StatTile(value: '${exercises.length}', label: 'Exercícios'),
                StatTile(value: '$improved', label: 'Com evolução'),
                StatTile(value: '${exercises.fold<int>(0, (s, e) => s + e.sessions)}', label: 'Registros'),
              ],
            ),
          ),
          for (final exercise in exercises) _ExerciseCard(exercise: exercise),
        ];
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});
  final ExerciseLoad exercise;

  @override
  Widget build(BuildContext context) {
    final change = exercise.change;
    final color = change > 0 ? Colors.green.shade700 : (change < 0 ? AppColors.error : Colors.grey);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(
                  change == 0 ? '=' : '${change > 0 ? '+' : ''}${_kg(change)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_kg(exercise.firstWeight)} → ${_kg(exercise.lastWeight)} · melhor ${_kg(exercise.bestWeight)} · '
              '${exercise.sessions} registro${exercise.sessions == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (exercise.points.length >= 2) ...[
              const SizedBox(height: 8),
              SimpleLineChart(values: exercise.points, height: 60, color: color == Colors.grey ? AppColors.blue : color),
            ],
          ],
        ),
      ),
    );
  }
}
