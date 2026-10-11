import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

/// Aba "Relatórios": resumo da semana + relatórios em tela (cada um com PDF no topo).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryProvider);
    final l = context.l10n;

    final reports = [
      (l.reportLoadEvolution, l.reportLoadEvolutionDesc, Icons.trending_up, '/reports/load-evolution'),
      (l.reportBody, l.reportBodyDesc, Icons.monitor_weight, '/reports/body'),
      (l.reportVolume, l.reportVolumeDesc, Icons.fitness_center, '/reports/volume'),
      (l.reportFrequency, l.reportFrequencyDesc, Icons.calendar_month, '/reports/frequency'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.reportsTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(weeklySummaryProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summaryAsync.when(
              data: (summary) => _WeeklySummaryCard(summary: summary),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l.errLoadWeeklySummary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.reportsYourReports, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final (title, description, icon, route) in reports)
              Card(
                child: ListTile(
                  leading: Icon(icon, color: AppColors.orange),
                  title: Text(title),
                  subtitle: Text(description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(route),
                ),
              ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.orange),
                title: Text(l.reportPlanPdf),
                subtitle: Text(l.reportPlanPdfDesc),
                trailing: const Icon(Icons.download),
                onTap: () => sharePdfReport(context, ref, ReportPdf.plan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.summary});
  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final evolution = summary.tonnageEvolutionPercentage;
    return ReportCard(
      title: l.weeklySummaryTitle,
      subtitle: summary.weekPeriod.isEmpty ? null : summary.weekPeriod,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatTile(value: '${summary.workoutsExecuted}/${summary.workoutsPlanned}', label: l.statWorkouts),
              StatTile(value: '${summary.trainingTimeMinutes.round()} min', label: l.statTime),
              StatTile(value: '${summary.totalTonnageKg.round()} kg', label: l.statTonnage),
            ],
          ),
          if (evolution != null) ...[
            const SizedBox(height: 12),
            Text(
              evolution >= 0
                  ? l.tonnageEvolutionUp(evolution.toStringAsFixed(0))
                  : l.tonnageEvolutionDown(evolution.toStringAsFixed(0)),
              style: TextStyle(color: evolution >= 0 ? Colors.green.shade700 : AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
