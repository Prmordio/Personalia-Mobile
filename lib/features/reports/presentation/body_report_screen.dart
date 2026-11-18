import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'report_format.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

class BodyReportScreen extends StatelessWidget {
  const BodyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ReportScaffold<BodyReport>(
      title: l.reportBody,
      provider: bodyReportProvider,
      pdf: ReportPdf.biometrics,
      builder: (context, report) {
        final fmt = ReportFormat.of(context);
        final weighIns = report.history.where((h) => h.weight != null).toList();
        final change = report.weightChange;
        return [
          ReportCard(
            title: l.reportBodyToday,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatTile(value: fmt.kg(report.weight), label: l.reportBodyWeight),
                    StatTile(value: '${fmt.number(report.height, decimals: 0)} cm', label: l.reportBodyHeight),
                    StatTile(value: fmt.number(report.bmi), label: l.reportBodyBmi),
                  ],
                ),
                if (report.bmiCategory != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Chip(
                      label: Text(l.reportBodyBmiCategory(report.bmiCategory!)),
                      backgroundColor: AppColors.orange.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ReportCard(
            title: l.reportBodyWeightEvolution,
            subtitle: switch (change) {
              null => null,
              < 0 => l.reportBodyWeightLost(fmt.number(-change)),
              > 0 => l.reportBodyWeightGained(fmt.number(change)),
              _ => l.reportBodyWeightStable,
            },
            child: weighIns.length < 2
                ? Text(l.reportBodyChartHint, style: const TextStyle(color: Colors.grey))
                : SimpleLineChart(
                    values: weighIns.map((h) => h.weight!).toList(),
                    semanticLabel:
                        '${l.reportBodyWeightEvolution}: '
                        '${weighIns.map((h) => '${fmt.shortDate(h.date)} ${fmt.kg(h.weight)}').join(', ')}',
                  ),
          ),
          if (weighIns.isNotEmpty)
            ReportCard(
              title: l.reportBodyHistory,
              child: Column(
                children: [
                  for (var i = weighIns.length - 1; i >= 0; i--)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(fmt.kg(weighIns[i].weight)),
                      subtitle: Text(fmt.fullDate(weighIns[i].date)),
                      trailing: i == 0 ? null : _Delta(weighIns[i].weight! - weighIns[i - 1].weight!),
                    ),
                ],
              ),
            ),
        ];
      },
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta(this.value);
  final num value;

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const Text('=', style: TextStyle(color: Colors.grey));
    final down = value < 0;
    return Text(
      ReportFormat.of(context).signedKg(value),
      style: TextStyle(color: down ? Colors.green.shade700 : AppColors.error, fontWeight: FontWeight.w600),
    );
  }
}
