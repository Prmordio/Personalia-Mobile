import 'execution_rule_catalog.dart';
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

  /// `down > up`: o sinal SOBE durante o esforço (panturrilha, tríceps na polia) e a rep vai
  /// do repouso (≤ up) ao pico (≥ down) e volta.
  bool get rising => down > up;

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
    this.tolerance = 0,
    required this.unit,
    required this.severity,
    required this.weight,
    required this.joints,
    required this.cue,
    this.label = const {},
  });

  final String id;
  final String signal;
  final Aggregation agg;
  final CheckOp op;
  final double target;

  /// Folga além do [target] antes de acusar erro: a pose do celular erra alguns graus/%,
  /// e um valor colado no limite não deve custar pontos.
  final double tolerance;
  final String unit;
  final IssueSeverity severity;

  /// Pontos de nota perdidos quando todas as reps falham (proporcional às reps que falham).
  final double weight;

  /// Articulações destacadas no overlay quando a verificação falha.
  final List<Joint> joints;

  /// Dica curta por idioma (`pt`, `en`, `es`) — fallback offline quando a IA não responde.
  final Map<String, String> cue;

  /// Nome do erro por idioma, cadastrado no painel.
  final Map<String, String> label;

  bool passes(double value) => op == CheckOp.lte ? value <= target + tolerance : value >= target - tolerance;

  String cueFor(String language) => cue[language] ?? cue['pt'] ?? cue.values.first;

  String? labelFor(String language) => label[language] ?? label['pt'];

  factory RuleCheck.fromJson(Map<String, dynamic> json) => RuleCheck(
        id: json['id'] as String,
        signal: json['signal'] as String,
        agg: Aggregation.values.byName(json['agg'] as String? ?? 'max'),
        op: CheckOp.values.byName(json['op'] as String),
        target: (json['target'] as num).toDouble(),
        tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '',
        severity: IssueSeverity.values.byName(json['severity'] as String? ?? 'medium'),
        weight: (json['weight'] as num?)?.toDouble() ?? 20,
        joints: [for (final j in json['joints'] as List? ?? const []) Joint.values.byName(j as String)],
        cue: Map<String, String>.from(json['cue'] as Map),
        label: Map<String, String>.from(json['label'] as Map? ?? const {}),
      );
}

/// Versão do formato de regra que este app entende; regras mais novas são ignoradas.
const supportedRuleSchemaVersion = 1;

/// Posição da câmera em relação ao aluno; muda só as instruções de enquadramento.
enum CameraView { side, front }

/// Regras de um exercício como dados, cadastradas no painel (trainer `execution_rule_sets`):
/// novo exercício = novo cadastro, sem mudar o motor — desde que use sinais que o app mede.
class ExerciseRuleSet {
  const ExerciseRuleSet({
    required this.exercise,
    required this.version,
    required this.minConfidence,
    required this.rep,
    required this.checks,
    this.name = '',
    this.schemaVersion = supportedRuleSchemaVersion,
    this.exerciseNames = const [],
    this.view = CameraView.side,
  });

  final String exercise;
  final String version;
  final double minConfidence;
  final RepRule rep;
  final List<RuleCheck> checks;
  final String name;
  final int schemaVersion;

  /// Nomes de exercício (normalizados) ligados a esta regra no painel.
  final List<String> exerciseNames;
  final CameraView view;

  factory ExerciseRuleSet.fromJson(Map<String, dynamic> json) => ExerciseRuleSet(
        exercise: json['exercise'] as String,
        version: json['version'].toString(),
        minConfidence: (json['minConfidence'] as num?)?.toDouble() ?? 0.5,
        rep: RepRule.fromJson(json['rep'] as Map<String, dynamic>),
        checks: [for (final c in json['checks'] as List) RuleCheck.fromJson(c as Map<String, dynamic>)],
        name: json['name'] as String? ?? '',
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? supportedRuleSchemaVersion,
        exerciseNames: List<String>.from(json['exerciseNames'] as List? ?? const []),
        view: CameraView.values.asNameMap()[json['view']] ?? CameraView.side,
      );
}

/// Origem das regras publicadas (cadastro do painel, com cache local).
abstract class RuleSetRepository {
  Future<ExecutionRuleCatalog> catalog();

  Future<ExerciseRuleSet> load(String exerciseKey);
}
