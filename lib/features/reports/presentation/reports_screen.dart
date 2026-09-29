import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

/// Aba "Relatórios": resumo da semana + relatórios em tela (cada um com PDF no topo).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const _reports = [
    ('Evolução de cargas', 'Quanto suas cargas subiram em cada exercício', Icons.trending_up, '/reports/load-evolution'),
    ('Medidas corporais', 'Peso, IMC e histórico de pesagens', Icons.monitor_weight, '/reports/body'),
    ('Volume de treino', 'Tonelagem levantada em cada treino', Icons.fitness_center, '/reports/volume'),
    ('Frequência', 'Calendário do mês e treinos por semana', Icons.calendar_month, '/reports/frequency'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
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
              error: (error, stackTrace) => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Não foi possível carregar o resumo da semana.'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Seus relatórios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final (title, description, icon, route) in _reports)
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
                title: const Text('Plano de treino (PDF)'),
                subtitle: const Text('Todos os dias e exercícios do seu plano'),
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
    final evolution = summary.tonnageEvolutionPercentage;
    return ReportCard(
      title: 'Resumo da semana',
      subtitle: summary.weekPeriod.isEmpty ? null : summary.weekPeriod,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatTile(value: '${summary.workoutsExecuted}/${summary.workoutsPlanned}', label: 'Treinos'),
              StatTile(value: '${summary.trainingTimeMinutes.round()} min', label: 'Tempo'),
              StatTile(value: '${summary.totalTonnageKg.round()} kg', label: 'Tonelagem'),
            ],
          ),
          if (evolution != null) ...[
            const SizedBox(height: 12),
            Text(
              '${evolution >= 0 ? '📈 +' : '📉 '}${evolution.toStringAsFixed(0)}% de tonelagem vs. semana passada',
              style: TextStyle(color: evolution >= 0 ? Colors.green.shade700 : AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
