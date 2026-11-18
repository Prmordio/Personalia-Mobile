import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../data/reports_api.dart';
import 'report_format.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_scaffold.dart';

class FrequencyReportScreen extends StatelessWidget {
  const FrequencyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ReportScaffold<FrequencyReport>(
      title: l.reportFrequency,
      provider: frequencyReportProvider,
      pdf: ReportPdf.attendance,
      builder: (context, report) {
        final fmt = ReportFormat.of(context);
        final diff = report.trainedThisMonth - report.trainedLastMonth;
        return [
          ReportCard(
            title: report.monthLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatTile(value: '${report.trainedThisMonth}', label: l.reportFreqDaysTrained),
                    StatTile(value: '${report.trainedLastMonth}', label: l.reportFreqLastMonth),
                    StatTile(value: fmt.number(report.averagePerWeek), label: l.reportFreqAvgWeek),
                  ],
                ),
                if (report.trainedLastMonth > 0 || report.trainedThisMonth > 0) ...[
                  const SizedBox(height: 12),
                  Text(switch (diff) {
                    0 => l.reportFreqSamePace,
                    > 0 => l.reportFreqMoreDays(diff),
                    _ => l.reportFreqFewerDays(-diff),
                  }, style: const TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 16),
                _MonthCalendar(report: report),
              ],
            ),
          ),
          ReportCard(
            title: l.reportFreqPerWeek,
            subtitle: l.reportFreqLast8Weeks,
            child: SimpleBarChart(
              values: report.weekly.map((w) => w.count).toList(),
              labels: report.weekly.map((w) => fmt.shortDate(w.weekStart)).toList(),
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
    final l = context.l10n;
    // narrowWeekdays começa no domingo, igual ao firstWeekday do backend.
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    final cells = [for (var i = 0; i < report.firstWeekday; i++) null, for (var d = 1; d <= report.daysInMonth; d++) d];
    return Column(
      children: [
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(w, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
              ),
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
                Semantics(
                  label: report.trainedDays.contains(day)
                      ? l.reportCalendarDayTrained(day)
                      : l.reportCalendarDayRest(day),
                  excludeSemantics: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: report.trainedDays.contains(day)
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: day == today ? Border.all(color: AppColors.blue, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: report.trainedDays.contains(day)
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: report.trainedDays.contains(day) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
