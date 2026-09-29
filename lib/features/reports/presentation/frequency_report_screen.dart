import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

final _day = DateFormat('dd/MM');
const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

class FrequencyReportScreen extends StatelessWidget {
  const FrequencyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScaffold<FrequencyReport>(
      title: 'Frequência',
      provider: frequencyReportProvider,
      pdf: ReportPdf.attendance,
      builder: (context, report) {
        final diff = report.trainedThisMonth - report.trainedLastMonth;
        return [
          ReportCard(
            title: report.monthLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatTile(value: '${report.trainedThisMonth}', label: 'Dias treinados'),
                    StatTile(value: '${report.trainedLastMonth}', label: 'Mês passado'),
                    StatTile(value: report.averagePerWeek.toString().replaceAll('.', ','), label: 'Média/semana'),
                  ],
                ),
                if (report.trainedLastMonth > 0 || report.trainedThisMonth > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    diff >= 0
                        ? '💪 ${diff == 0 ? 'Mesmo ritmo' : '$diff dia${diff == 1 ? '' : 's'} a mais'} que no mês passado'
                        : '${-diff} dia${diff == -1 ? '' : 's'} a menos que no mês passado — bora recuperar!',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                _MonthCalendar(report: report),
              ],
            ),
          ),
          ReportCard(
            title: 'Treinos por semana',
            subtitle: 'Últimas 8 semanas',
            child: SimpleBarChart(
              values: report.weekly.map((w) => w.count).toList(),
              labels: report.weekly.map((w) => _day.format(w.weekStart)).toList(),
              height: 100,
              highlightLast: true,
            ),
          ),
        ];
      },
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.report});
  final FrequencyReport report;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().day;
    final cells = [
      for (var i = 0; i < report.firstWeekday; i++) null,
      for (var d = 1; d <= report.daysInMonth; d++) d,
    ];
    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(child: Center(child: Text(w, style: const TextStyle(color: Colors.grey, fontSize: 12)))),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final day in cells)
              if (day == null)
                const SizedBox.shrink()
              else
                Container(
                  decoration: BoxDecoration(
                    color: report.trainedDays.contains(day) ? AppColors.orange : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: day == today ? Border.all(color: AppColors.blue, width: 2) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: report.trainedDays.contains(day) ? Colors.white : Colors.black87,
                      fontWeight: report.trainedDays.contains(day) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
