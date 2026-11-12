import '../../../l10n/app_localizations.dart';
import '../domain/exercise_rule_set.dart';
import '../domain/execution_report.dart';
import '../domain/pose_frame.dart';
import 'widgets/skeleton_overlay_painter.dart';

/// Nome do erro cadastrado no painel; regras antigas sem nome caem nas traduções do app.
String issueLabel(AppLocalizations l, RuleCheck check, String language) =>
    check.labelFor(language) ??
    switch (check.id) {
      'depth' => l.execIssueDepth,
      'trunk_lean' => l.execIssueTrunkLean,
      'heel_lift' => l.execIssueHeelLift,
      'tempo' => l.execIssueTempo,
      _ => check.id,
    };

/// [extraDigits] acrescenta casas decimais além da precisão padrão da unidade.
String formatMeasure(double value, String unit, {int extraDigits = 0}) {
  String fixed(double v, int digits) => v.toStringAsFixed(digits + extraDigits);
  return switch (unit) {
    'deg' => '${fixed(value, 0)}°',
    'pct_shin' => '${fixed(value, 0)}%',
    'ms' => '${fixed(value / 1000, 1)}s',
    _ => fixed(value, 1),
  };
}

/// Valor medido de um check: se o arredondamento o deixar igual ao alvo ("8% · alvo ≤ 8%"),
/// mostra uma casa a mais para ficar claro que passou do limite.
String formatMeasured(double value, RuleCheck check) {
  final plain = formatMeasure(value, check.unit);
  return plain == formatMeasure(check.target, check.unit) ? formatMeasure(value, check.unit, extraDigits: 1) : plain;
}

String formatTarget(RuleCheck check) => '${check.op == CheckOp.lte ? '≤' : '≥'} ${formatMeasure(check.target, check.unit)}';

/// Ângulos que sabemos desenhar no overlay, por sinal do rule set.
const _angleSignals = {
  'knee_angle': (vertex: Joint.knee, fixed: Joint.ankle, moving: Joint.hip),
  'hip_angle': (vertex: Joint.hip, fixed: Joint.knee, moving: Joint.shoulder),
  'elbow_angle': (vertex: Joint.elbow, fixed: Joint.shoulder, moving: Joint.wrist),
  'shoulder_angle': (vertex: Joint.shoulder, fixed: Joint.hip, moving: Joint.elbow),
  'ankle_angle': (vertex: Joint.ankle, fixed: Joint.knee, moving: Joint.footIndex),
};

AngleAnnotation? annotationFor(List<ExecutionIssue> active) {
  for (final issue in active) {
    final spec = _angleSignals[issue.check.signal];
    if (spec != null) {
      return AngleAnnotation(
        vertex: spec.vertex,
        fixedArm: spec.fixed,
        movingArm: spec.moving,
        target: issue.check.target,
      );
    }
  }
  return null;
}
