import '../../../l10n/app_localizations.dart';
import '../domain/exercise_rule_set.dart';
import '../domain/execution_report.dart';
import '../domain/pose_frame.dart';
import 'widgets/skeleton_overlay_painter.dart';

String issueLabel(AppLocalizations l, String id) => switch (id) {
      'depth' => l.execIssueDepth,
      'trunk_lean' => l.execIssueTrunkLean,
      'heel_lift' => l.execIssueHeelLift,
      'tempo' => l.execIssueTempo,
      _ => id,
    };

String formatMeasure(double value, String unit) => switch (unit) {
      'deg' => '${value.round()}°',
      'pct_shin' => '${value.round()}%',
      'ms' => '${(value / 1000).toStringAsFixed(1)}s',
      _ => value.toStringAsFixed(1),
    };

String formatTarget(RuleCheck check) => '${check.op == CheckOp.lte ? '≤' : '≥'} ${formatMeasure(check.target, check.unit)}';

/// Ângulos que sabemos desenhar no overlay, por sinal do rule set.
const _angleSignals = {
  'knee_angle': (vertex: Joint.knee, fixed: Joint.ankle, moving: Joint.hip),
  'hip_angle': (vertex: Joint.hip, fixed: Joint.knee, moving: Joint.shoulder),
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
