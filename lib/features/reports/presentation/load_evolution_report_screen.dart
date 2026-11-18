import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'report_format.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

/// Evolução de cargas por exercício (primeira → última, melhor carga).
class LoadEvolutionReportScreen extends StatelessWidget {
  const LoadEvolutionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ReportScaffold<List<ExerciseLoad>>(
      title: l.reportLoadEvolution,
      provider: loadEvolutionProvider,
      pdf: ReportPdf.workout,
      isEmpty: (exercises) => exercises.isEmpty,
      emptyMessage: l.reportLoadEmpty,
      builder: (context, exercises) {
        final improved = exercises.where((e) => e.change > 0).length;
        return [
          ReportCard(
            title: l.reportSummary,
            child: Row(
              children: [
                StatTile(value: '${exercises.length}', label: l.reportStatExercises),
                StatTile(value: '$improved', label: l.reportStatImproved),
                StatTile(value: '${exercises.fold<int>(0, (s, e) => s + e.sessions)}', label: l.reportStatEntries),
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
    final fmt = ReportFormat.of(context);
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
                Expanded(
                  child: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  change == 0 ? '=' : fmt.signedKg(change),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.reportLoadExerciseDetail(
                fmt.kg(exercise.firstWeight),
                fmt.kg(exercise.lastWeight),
                fmt.kg(exercise.bestWeight),
                exercise.sessions,
              ),
              style: const TextStyle(color: Colors.grey),
            ),
            if (exercise.points.length >= 2) ...[
              const SizedBox(height: 8),
              SimpleLineChart(
                values: exercise.points,
                height: 60,
                color: color == Colors.grey ? AppColors.blue : color,
                semanticLabel: '${exercise.name}: ${exercise.points.map(fmt.kg).join(', ')}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
