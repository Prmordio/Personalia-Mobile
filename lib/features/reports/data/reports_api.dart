import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
num? _numOrNull(dynamic v) => v == null ? null : (v is num ? v : num.tryParse('$v'));
DateTime _date(dynamic v) => DateTime.tryParse('$v')?.toLocal() ?? DateTime.now();

class WeeklySummary {
  WeeklySummary({
    required this.weekPeriod,
    required this.workoutsExecuted,
    required this.workoutsPlanned,
    required this.trainingTimeMinutes,
    required this.totalTonnageKg,
    this.tonnageEvolutionPercentage,
  });

  final String weekPeriod;
  final int workoutsExecuted;
  final int workoutsPlanned;
  final num trainingTimeMinutes;
  final num totalTonnageKg;
  final num? tonnageEvolutionPercentage;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
        weekPeriod: json['weekPeriod'] ?? '',
        workoutsExecuted: _num(json['workoutsExecuted']).toInt(),
        workoutsPlanned: _num(json['workoutsPlanned']).toInt(),
        trainingTimeMinutes: _num(json['trainingTimeMinutes']),
        totalTonnageKg: _num(json['totalTonnageKg']),
        tonnageEvolutionPercentage: _numOrNull(json['tonnageEvolutionPercentage']),
      );
}

class VolumeSession {
  VolumeSession({required this.date, required this.workoutDay, required this.totalVolume, required this.exerciseCount});
  final DateTime date;
  final String workoutDay;
  final num totalVolume;
  final int exerciseCount;

  factory VolumeSession.fromJson(Map<String, dynamic> json) => VolumeSession(
        date: _date(json['date']),
        workoutDay: json['workoutDay'] ?? '',
        totalVolume: _num(json['totalVolume']),
        exerciseCount: _num(json['exerciseCount']).toInt(),
      );
}

class VolumeReport {
  VolumeReport({required this.sessions, required this.totalVolume, required this.averageVolume, this.bestSession});
  final List<VolumeSession> sessions;
  final num totalVolume;
  final num averageVolume;
  final VolumeSession? bestSession;

  factory VolumeReport.fromJson(Map<String, dynamic> json) => VolumeReport(
        sessions: (json['sessions'] as List? ?? []).map((s) => VolumeSession.fromJson(Map<String, dynamic>.from(s))).toList(),
        totalVolume: _num(json['totalVolume']),
        averageVolume: _num(json['averageVolume']),
        bestSession: json['bestSession'] != null ? VolumeSession.fromJson(Map<String, dynamic>.from(json['bestSession'])) : null,
      );
}

class FrequencyReport {
  FrequencyReport({
    required this.monthLabel,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.trainedDays,
    required this.trainedThisMonth,
    required this.trainedLastMonth,
    required this.weekly,
    required this.averagePerWeek,
  });

  final String monthLabel;
  final int daysInMonth;

  /// 0 = domingo.
  final int firstWeekday;
  final Set<int> trainedDays;
  final int trainedThisMonth;
  final int trainedLastMonth;
  final List<({DateTime weekStart, int count})> weekly;
  final num averagePerWeek;

  factory FrequencyReport.fromJson(Map<String, dynamic> json) {
    final month = Map<String, dynamic>.from(json['month'] ?? {});
    return FrequencyReport(
      monthLabel: month['label'] ?? '',
      daysInMonth: _num(month['daysInMonth']).toInt(),
      firstWeekday: _num(month['firstWeekday']).toInt(),
      trainedDays: (month['trainedDays'] as List? ?? []).map((d) => _num(d).toInt()).toSet(),
      trainedThisMonth: _num(json['trainedThisMonth']).toInt(),
      trainedLastMonth: _num(json['trainedLastMonth']).toInt(),
      weekly: (json['weekly'] as List? ?? [])
          .map((w) => (weekStart: DateTime.parse('${w['weekStart']}'), count: _num(w['count']).toInt()))
          .toList(),
      averagePerWeek: _num(json['averagePerWeek']),
    );
  }
}

class BodyReport {
  BodyReport({this.weight, this.height, this.bmi, this.bmiCategory, required this.history, this.weightChange});
  final num? weight;
  final num? height;
  final num? bmi;
  final String? bmiCategory;
  final List<({DateTime date, num? weight})> history;
  final num? weightChange;

  factory BodyReport.fromJson(Map<String, dynamic> json) {
    final current = Map<String, dynamic>.from(json['current'] ?? {});
    return BodyReport(
      weight: _numOrNull(current['weight']),
      height: _numOrNull(current['height']),
      bmi: _numOrNull(current['bmi']),
      bmiCategory: current['bmiCategory'],
      history: (json['history'] as List? ?? []).map((h) => (date: _date(h['date']), weight: _numOrNull(h['weight']))).toList(),
      weightChange: _numOrNull(json['weightChange']),
    );
  }
}

class ExerciseLoad {
  ExerciseLoad({
    required this.name,
    required this.sessions,
    required this.firstWeight,
    required this.lastWeight,
    required this.bestWeight,
    required this.change,
    required this.points,
  });

  final String name;
  final int sessions;
  final num firstWeight;
  final num lastWeight;
  final num bestWeight;
  final num change;
  final List<num> points;

  factory ExerciseLoad.fromJson(Map<String, dynamic> json) => ExerciseLoad(
        name: json['name'] ?? '',
        sessions: _num(json['sessions']).toInt(),
        firstWeight: _num(json['firstWeight']),
        lastWeight: _num(json['lastWeight']),
        bestWeight: _num(json['bestWeight']),
        change: _num(json['change']),
        points: (json['points'] as List? ?? []).map((p) => _num(p['weight'])).toList(),
      );
}

/// Relatórios em PDF que o reports-api gera (mesmos tipos liberados no gateway).
enum ReportPdf {
  plan('plan', 'Plano de treino'),
  workout('workout', 'Histórico de treinos'),
  biometrics('biometrics', 'Medidas corporais'),
  volume('volume', 'Volume de treino'),
  attendance('attendance', 'Frequência');

  const ReportPdf(this.type, this.title);
  final String type;
  final String title;
}

class ReportsApi {
  ReportsApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> _get(String report) async {
    final response = await _dio.get('/app/reports/$report');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<WeeklySummary> getWeeklySummary() async => WeeklySummary.fromJson(await _get('weekly-summary'));
  Future<VolumeReport> getVolume() async => VolumeReport.fromJson(await _get('volume'));
  Future<FrequencyReport> getFrequency() async => FrequencyReport.fromJson(await _get('frequency'));
  Future<BodyReport> getBody() async => BodyReport.fromJson(await _get('body'));

  Future<List<ExerciseLoad>> getLoadEvolution() async {
    final json = await _get('load-evolution');
    return (json['exercises'] as List? ?? []).map((e) => ExerciseLoad.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Uint8List> downloadPdf(ReportPdf report) async {
    final response = await _dio.get<List<int>>(
      '/app/reports/pdf/${report.type}',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}

final reportsApiProvider = Provider<ReportsApi>((ref) => ReportsApi(ref.watch(apiClientProvider).dio));

final weeklySummaryProvider = FutureProvider.autoDispose<WeeklySummary>((ref) => ref.watch(reportsApiProvider).getWeeklySummary());
final volumeReportProvider = FutureProvider.autoDispose<VolumeReport>((ref) => ref.watch(reportsApiProvider).getVolume());
final frequencyReportProvider = FutureProvider.autoDispose<FrequencyReport>((ref) => ref.watch(reportsApiProvider).getFrequency());
final bodyReportProvider = FutureProvider.autoDispose<BodyReport>((ref) => ref.watch(reportsApiProvider).getBody());
final loadEvolutionProvider = FutureProvider.autoDispose<List<ExerciseLoad>>((ref) => ref.watch(reportsApiProvider).getLoadEvolution());
