import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/reports/data/reports_api.dart';
import 'package:personalia_app/features/reports/presentation/body_report_screen.dart';
import 'package:personalia_app/features/reports/presentation/frequency_report_screen.dart';
import 'package:personalia_app/features/reports/presentation/load_evolution_report_screen.dart';
import 'package:personalia_app/features/reports/presentation/volume_report_screen.dart';

/// JSON no mesmo formato devolvido pelo gateway (/app/reports/*).
final _volumeJson = {
  'sessions': [
    {'date': '2026-09-01T12:00:00Z', 'workoutDay': 'Treino A', 'totalVolume': 1200, 'exerciseCount': 2},
    {'date': '2026-09-25T12:00:00Z', 'workoutDay': 'Treino B', 'totalVolume': 3420, 'exerciseCount': 5},
  ],
  'totalVolume': 4620,
  'averageVolume': 2310,
  'bestSession': {'date': '2026-09-25T12:00:00Z', 'workoutDay': 'Treino B', 'totalVolume': 3420, 'exerciseCount': 5},
};
final _frequencyJson = {
  'month': {'label': 'Setembro 2026', 'year': 2026, 'month': 9, 'daysInMonth': 30, 'firstWeekday': 2, 'trainedDays': [1, 10, 25]},
  'trainedThisMonth': 3,
  'trainedLastMonth': 5,
  'weekly': [
    for (var i = 0; i < 8; i++) {'weekStart': '2026-08-${(10 + i * 7).clamp(10, 31)}', 'count': i % 3},
  ],
  'averagePerWeek': 0.4,
  'totalWorkouts': 3,
};
final _bodyJson = {
  'current': {'weight': 112, 'height': 175, 'bmi': 36.57, 'bmiCategory': 'Obesidade'},
  'history': [
    {'date': '2026-08-01T10:00:00Z', 'weight': 115, 'bmi': 37.55},
    {'date': '2026-09-20T10:00:00Z', 'weight': 112, 'bmi': 36.57},
  ],
  'weightChange': -3,
};
final _loadJson = [
  {
    'name': 'Supino',
    'sessions': 3,
    'firstWeight': 40,
    'lastWeight': 42.5,
    'bestWeight': 45,
    'change': 2.5,
    'points': [
      {'date': '2026-09-01', 'weight': 40},
      {'date': '2026-09-10', 'weight': 45},
      {'date': '2026-09-25', 'weight': 42.5},
    ],
  },
];

Future<void> _pump(WidgetTester tester, Widget screen, List<Override> overrides) async {
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(home: screen)));
  await tester.pumpAndSettle();
}

void main() {
  test('should_parse_the_gateway_payloads', () {
    final volume = VolumeReport.fromJson(_volumeJson);
    expect(volume.sessions.map((s) => s.totalVolume), [1200, 3420]);
    expect(volume.bestSession?.workoutDay, 'Treino B');

    final frequency = FrequencyReport.fromJson(_frequencyJson);
    expect(frequency.trainedDays, {1, 10, 25});
    expect(frequency.weekly, hasLength(8));

    final body = BodyReport.fromJson(_bodyJson);
    expect(body.weightChange, -3);
    expect(body.history.map((h) => h.weight), [115, 112]);

    final load = ExerciseLoad.fromJson(_loadJson.first);
    expect(load.points, [40, 45, 42.5]);
  });

  testWidgets('should_render_the_volume_report', (tester) async {
    await _pump(tester, const VolumeReportScreen(), [
      volumeReportProvider.overrideWith((ref) async => VolumeReport.fromJson(_volumeJson)),
    ]);
    expect(find.text('Tonelagem'), findsOneWidget);
    expect(find.text('Treino B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('should_show_the_empty_state_without_sessions', (tester) async {
    await _pump(tester, const VolumeReportScreen(), [
      volumeReportProvider.overrideWith(
        (ref) async => VolumeReport.fromJson({'sessions': [], 'totalVolume': 0, 'averageVolume': 0}),
      ),
    ]);
    expect(find.textContaining('Registre as cargas'), findsOneWidget);
  });

  testWidgets('should_render_the_frequency_calendar', (tester) async {
    await _pump(tester, const FrequencyReportScreen(), [
      frequencyReportProvider.overrideWith((ref) async => FrequencyReport.fromJson(_frequencyJson)),
    ]);
    expect(find.text('Setembro 2026'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.textContaining('a menos que no mês passado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('should_render_body_measures_and_weight_loss', (tester) async {
    await _pump(tester, const BodyReportScreen(), [
      bodyReportProvider.overrideWith((ref) async => BodyReport.fromJson(_bodyJson)),
    ]);
    expect(find.text('IMC: Obesidade'), findsOneWidget);
    expect(find.textContaining('3 kg a menos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('should_render_load_evolution_per_exercise', (tester) async {
    await _pump(tester, const LoadEvolutionReportScreen(), [
      loadEvolutionProvider.overrideWith((ref) async => _loadJson.map(ExerciseLoad.fromJson).toList()),
    ]);
    expect(find.text('Supino'), findsOneWidget);
    expect(find.text('+2,5 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
