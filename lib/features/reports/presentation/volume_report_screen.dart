import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/reports_api.dart';
import 'report_format.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

class VolumeReportScreen extends StatelessWidget {
  const VolumeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ReportScaffold<VolumeReport>(
      title: l.reportVolume,
      provider: volumeReportProvider,
      pdf: ReportPdf.volume,
      isEmpty: (report) => report.sessions.isEmpty,
      emptyMessage: l.reportVolumeEmpty,
      builder: (context, report) {
        final fmt = ReportFormat.of(context);
        return [
          ReportCard(
            title: l.reportVolumeTonnage,
            subtitle: l.reportVolumeTonnageDesc,
            child: Row(
              children: [
                StatTile(value: fmt.kg(report.totalVolume), label: l.reportVolumeTotal),
                StatTile(value: fmt.kg(report.averageVolume), label: l.reportVolumeAverage),
                StatTile(value: fmt.kg(report.bestSession?.totalVolume ?? 0), label: l.reportVolumeBest),
              ],
            ),
          ),
          ReportCard(
            title: l.reportVolumePerWorkout,
            subtitle: l.reportVolumeLastN(report.sessions.length),
            child: SimpleBarChart(
              values: report.sessions.map((s) => s.totalVolume).toList(),
              labels: report.sessions.map((s) => fmt.shortDate(s.date)).toList(),
              highlightLast: true,
              valueLabel: fmt.kg,
            ),
          ),
          ReportCard(
            title: l.reportVolumeWorkouts,
            child: Column(
              children: [
                for (final s in report.sessions.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.workoutDay.isEmpty ? l.reportVolumeWorkoutFallback : s.workoutDay),
                    subtitle: Text(l.reportVolumeSessionDetail(fmt.shortDate(s.date), s.exerciseCount)),
                    trailing: Text(fmt.kg(s.totalVolume), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
