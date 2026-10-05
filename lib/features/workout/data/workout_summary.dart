import '../presentation/rest_timer_screen.dart';

class ExerciseSummary {
  const ExerciseSummary({
    required this.nome,
    required this.weight,
    required this.completedSets,
    required this.totalSets,
    required this.finished,
    this.reps,
    this.observation,
  });
  final String nome;
  final String weight;
  final int completedSets;
  final int totalSets;
  final bool finished;
  final String? reps;
  final String? observation;

  double get weightValue => double.tryParse(weight.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  int get repsValue => int.tryParse(RegExp(r'(\d+)').firstMatch(reps ?? '')?.group(1) ?? '0') ?? 0;
  double get volume => weightValue * completedSets * (repsValue > 0 ? repsValue : 1);
}

class WorkoutSummary {
  const WorkoutSummary({
    required this.dayName,
    required this.startedAt,
    required this.finishedAt,
    required this.exercises,
  });
  final String dayName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<ExerciseSummary> exercises;

  Duration get duration => finishedAt.difference(startedAt);

  String get durationFormatted {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  int get totalExercises => exercises.length;
  int get completedCount => exercises.where((e) => e.finished).length;

  double get totalVolume => exercises.fold(0.0, (sum, e) => sum + (e.finished ? e.volume : 0));

  String get totalVolumeFormatted {
    final v = totalVolume;
    if (v <= 0) return '—';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} t';
    return '${v.toStringAsFixed(0)} kg';
  }

  /// Constrói o summary a partir dos providers de cada exercício.
  static WorkoutSummary fromProviders({
    required String dayName,
    required DateTime startedAt,
    required List<({String nome, String? series, String? repeticoes, String? descanso})> exercises,
    required RestTimerState Function((String, int, int)) readState,
  }) {
    final now = DateTime.now();
    final summaries = exercises.map((ex) {
      final totalSecs = parseRestSeconds(ex.descanso);
      final totalSets = parseSetsCount(ex.series);
      final state = readState((ex.nome, totalSecs, totalSets));
      return ExerciseSummary(
        nome: ex.nome,
        weight: state.weight,
        completedSets: state.completedSets,
        totalSets: totalSets,
        finished: state.finished,
        reps: ex.repeticoes,
        observation: state.observation.isEmpty ? null : state.observation,
      );
    }).toList();
    return WorkoutSummary(dayName: dayName, startedAt: startedAt, finishedAt: now, exercises: summaries);
  }
}
