import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

final _date = DateFormat('dd/MM/yyyy');

String _fmt(num? v, {int decimals = 1}) =>
    v == null ? '—' : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(decimals)).replaceAll('.', ',');

class BodyReportScreen extends StatelessWidget {
  const BodyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<BodyReport>(
      title: 'Medidas corporais',
      provider: bodyReportProvider,
      pdf: ReportPdf.biometrics,
      builder: (context, report) {
        final weighIns = report.history.where((h) => h.weight != null).toList();
        final change = report.weightChange;
        return [
          ReportCard(
            title: 'Hoje',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatTile(value: '${_fmt(report.weight)} kg', label: 'Peso'),
                    StatTile(value: '${_fmt(report.height, decimals: 0)} cm', label: 'Altura'),
                    StatTile(value: _fmt(report.bmi), label: 'IMC'),
                  ],
                ),
                if (report.bmiCategory != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Chip(
                      label: Text('IMC: ${report.bmiCategory}'),
                      backgroundColor: AppColors.orange.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ReportCard(
            title: 'Evolução do peso',
            subtitle: change == null
                ? null
                : change < 0
                    ? '📉 ${_fmt(-change)} kg a menos desde a primeira pesagem'
                    : change > 0
                        ? '📈 ${_fmt(change)} kg a mais desde a primeira pesagem'
                        : 'Peso estável desde a primeira pesagem',
            child: weighIns.length < 2
                ? const Text(
                    'Com duas pesagens ou mais, o gráfico da sua evolução aparece aqui.',
                    style: TextStyle(color: Colors.grey),
                  )
                : SimpleLineChart(values: weighIns.map((h) => h.weight!).toList()),
          ),
          if (weighIns.isNotEmpty)
            ReportCard(
              title: 'Histórico de pesagens',
              child: Column(
                children: [
                  for (var i = weighIns.length - 1; i >= 0; i--)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${_fmt(weighIns[i].weight)} kg'),
                      subtitle: Text(_date.format(weighIns[i].date)),
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
      '${down ? '' : '+'}${_fmt(value)} kg',
      style: TextStyle(color: down ? Colors.green.shade700 : AppColors.error, fontWeight: FontWeight.w600),
    );
  }
}
