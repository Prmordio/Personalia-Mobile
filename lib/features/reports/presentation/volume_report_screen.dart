import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/reports_api.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

final _day = DateFormat('dd/MM');
final _kg = NumberFormat.decimalPattern('pt_BR');

class VolumeReportScreen extends StatelessWidget {
  const VolumeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<VolumeReport>(
      title: 'Volume de treino',
      provider: volumeReportProvider,
      pdf: ReportPdf.volume,
      isEmpty: (report) => report.sessions.isEmpty,
      emptyMessage: 'Registre as cargas durante os treinos para ver a tonelagem levantada em cada sessão.',
      builder: (context, report) => [
        ReportCard(
          title: 'Tonelagem',
          subtitle: 'Carga × séries × repetições de cada treino',
          child: Row(
            children: [
              StatTile(value: '${_kg.format(report.totalVolume)} kg', label: 'Total'),
              StatTile(value: '${_kg.format(report.averageVolume)} kg', label: 'Média/treino'),
              StatTile(value: '${_kg.format(report.bestSession?.totalVolume ?? 0)} kg', label: 'Melhor treino'),
            ],
          ),
        ),
        ReportCard(
          title: 'Por treino',
          subtitle: 'Últimos ${report.sessions.length} treinos',
          child: SimpleBarChart(
            values: report.sessions.map((s) => s.totalVolume).toList(),
            labels: report.sessions.map((s) => _day.format(s.date)).toList(),
            highlightLast: true,
          ),
        ),
        ReportCard(
          title: 'Treinos',
          child: Column(
            children: [
              for (final s in report.sessions.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.workoutDay.isEmpty ? 'Treino' : s.workoutDay),
                  subtitle: Text('${_day.format(s.date)} · ${s.exerciseCount} exercícios'),
                  trailing: Text('${_kg.format(s.totalVolume)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
