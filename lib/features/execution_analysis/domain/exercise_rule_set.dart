import 'pose_frame.dart';

enum CheckOp { lte, gte }

enum Aggregation { min, max }

enum IssueSeverity { low, medium, high }

/// Como contar as repetições: histerese no [signal] (ex.: ângulo do joelho).
class RepRule {
  const RepRule({required this.signal, required this.down, required this.up, required this.minDurationMs});
  final String signal;

  /// Abaixo disso a rep começa a contar como "descida".
  final double down;

  /// Acima disso a rep volta ao topo (concluída).
  final double up;
  final int minDurationMs;

  factory RepRule.fromJson(Map<String, dynamic> json) => RepRule(
        signal: json['signal'] as String,
        down: (json['down'] as num).toDouble(),
        up: (json['up'] as num).toDouble(),
        minDurationMs: (json['minDurationMs'] as num?)?.toInt() ?? 600,
      );
}

/// Uma verificação de técnica aplicada a cada rep.
///
/// [signal] é um sinal por quadro (`knee_angle`, `trunk_lean`, `heel_lift`…) agregado
/// com [agg] ao longo da rep, ou uma métrica da rep (`rep.eccentric_ms`).
class RuleCheck {
  const RuleCheck({
    required this.id,
    required this.signal,
    required this.agg,
    required this.op,
    required this.target,
    required this.unit,
    required this.severity,
    required this.weight,
    required this.joints,
    required this.cue,
  });

  final String id;
  final String signal;
  final Aggregation agg;
  final CheckOp op;
  final double target;
  final String unit;
  final IssueSeverity severity;

  /// Pontos de nota perdidos quando todas as reps falham (proporcional às reps que falham).
  final double weight;

  /// Articulações destacadas no overlay quando a verificação falha.
  final List<Joint> joints;

  /// Dica curta por idioma (`pt`, `en`, `es`) — fallback offline quando a IA não responde.
  final Map<String, String> cue;

  bool passes(double value) => op == CheckOp.lte ? value <= target : value >= target;

  String cueFor(String language) => cue[language] ?? cue['pt'] ?? cue.values.first;

  factory RuleCheck.fromJson(Map<String, dynamic> json) => RuleCheck(
        id: json['id'] as String,
        signal: json['signal'] as String,
        agg: Aggregation.values.byName(json['agg'] as String? ?? 'max'),
        op: CheckOp.values.byName(json['op'] as String),
        target: (json['target'] as num).toDouble(),
        unit: json['unit'] as String? ?? '',
        severity: IssueSeverity.values.byName(json['severity'] as String? ?? 'medium'),
        weight: (json['weight'] as num?)?.toDouble() ?? 20,
        joints: [for (final j in json['joints'] as List? ?? const []) Joint.values.byName(j as String)],
        cue: Map<String, String>.from(json['cue'] as Map),
      );
}

/// Regras de um exercício como dados (assets/execution_rules/*.json): novo exercício =
/// novo JSON, sem mudar o motor.
class ExerciseRuleSet {
  const ExerciseRuleSet({
    required this.exercise,
    required this.version,
    required this.minConfidence,
    required this.rep,
    required this.checks,
  });

  final String exercise;
  final String version;
  final double minConfidence;
  final RepRule rep;
  final List<RuleCheck> checks;

  factory ExerciseRuleSet.fromJson(Map<String, dynamic> json) => ExerciseRuleSet(
        exercise: json['exercise'] as String,
        version: json['version'].toString(),
        minConfidence: (json['minConfidence'] as num?)?.toDouble() ?? 0.5,
        rep: RepRule.fromJson(json['rep'] as Map<String, dynamic>),
        checks: [for (final c in json['checks'] as List) RuleCheck.fromJson(c as Map<String, dynamic>)],
      );
}

/// Origem dos rule sets (asset hoje; remoto depois sem mexer no motor).
abstract class RuleSetRepository {
  Future<ExerciseRuleSet> load(String exerciseKey);
}
