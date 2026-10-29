import 'exercise_rule_set.dart';
import 'pose_frame.dart';
import 'rep_segmenter.dart';

/// Onde (rep + instante) uma verificação falhou — o overlay pula para cá no "Ver".
class IssueHighlight {
  const IssueHighlight({required this.rep, required this.tMs, required this.value});
  final int rep;
  final int tMs;
  final double value;
}

class ExecutionIssue {
  const ExecutionIssue({required this.check, required this.highlights});

  final RuleCheck check;

  /// Uma por rep que falhou, em ordem de rep.
  final List<IssueHighlight> highlights;

  /// Reps (1-based) em que a verificação falhou.
  List<int> get reps => [for (final h in highlights) h.rep];

  /// Pior valor medido entre as reps que falharam.
  double get measured => worst.value;

  String get id => check.id;
  IssueSeverity get severity => check.severity;
  List<Joint> get joints => check.joints;

  IssueHighlight get worst => highlights.reduce((a, b) => compareWorse(a, b) <= 0 ? a : b);

  /// Ordena do pior para o melhor: em `lte` (≤ alvo) pior é maior; em `gte`, menor.
  int compareWorse(IssueHighlight a, IssueHighlight b) =>
      check.op == CheckOp.lte ? b.value.compareTo(a.value) : a.value.compareTo(b.value);

  Map<String, dynamic> toJson() => {
        'id': id,
        'severity': severity.name,
        'reps': reps,
        'measured': double.parse(measured.toStringAsFixed(1)),
        'target': check.target,
        'op': check.op.name,
        'unit': check.unit,
      };
}

class Fatigue {
  const Fatigue({required this.romDropPct, required this.fromRep});
  final int romDropPct;
  final int fromRep;

  Map<String, dynamic> toJson() => {'romDropPct': romDropPct, 'fromRep': fromRep};
}

/// Resultado medido on-device. É o que vai pro backend (sem imagens nem pose bruta) e o
/// que alimenta a tela de resultado.
class ExecutionReport {
  const ExecutionReport({
    required this.exercise,
    required this.ruleSetVersion,
    required this.side,
    required this.durationMs,
    required this.score,
    required this.reps,
    required this.issues,
    required this.unclearReps,
    required this.fatigue,
  });

  final String exercise;
  final String ruleSetVersion;
  final BodySide side;
  final int durationMs;
  final int score;
  final List<Rep> reps;
  final List<ExecutionIssue> issues;

  /// Reps em que o corpo não ficou visível o bastante — não são avaliadas.
  final List<int> unclearReps;
  final Fatigue? fatigue;

  int get repCount => reps.length;
  bool get hasReps => reps.isNotEmpty;

  Rep? repAt(int tMs) {
    for (final r in reps) {
      if (r.containsMs(tMs)) return r;
    }
    return null;
  }

  /// Issues cuja falha inclui a rep em andamento no instante [tMs].
  List<ExecutionIssue> issuesAt(int tMs) {
    final rep = repAt(tMs);
    if (rep == null) return const [];
    return [for (final i in issues) if (i.reps.contains(rep.index)) i];
  }

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'ruleSetVersion': ruleSetVersion,
        'view': 'side',
        'side': side.name,
        'durationMs': durationMs,
        'score': score,
        'repCount': repCount,
        'reps': [for (final r in reps) r.toJson()],
        'issues': [for (final i in issues) i.toJson()],
        'unclearReps': unclearReps,
        'fatigue': fatigue?.toJson(),
      };
}
