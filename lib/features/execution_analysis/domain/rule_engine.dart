import 'exercise_rule_set.dart';
import 'execution_report.dart';
import 'geometry.dart';
import 'pose_frame.dart';
import 'rep_segmenter.dart';
import 'signals.dart';

/// Abaixo disso a rep não é avaliada (corpo saiu do quadro / oclusão) — melhor dizer
/// "não consegui ver" do que acusar um erro que não houve.
const double minRepVisibleRatio = 0.6;
const double _fatigueDropThresholdPct = 15;

/// Métricas da própria rep que um check pode usar com o prefixo `rep.`.
final Map<String, double Function(Rep)> _repMetrics = {
  'rep.eccentric_ms': (r) => r.eccentricMs.toDouble(),
  'rep.concentric_ms': (r) => r.concentricMs.toDouble(),
};

/// Aplica um [ExerciseRuleSet] a uma sequência de pose: escolhe o lado visível, extrai os
/// sinais, conta as reps e avalia cada check por rep. Determinístico e sem dependências
/// de plataforma.
class RuleEngine {
  const RuleEngine(this.ruleSet);
  final ExerciseRuleSet ruleSet;

  ExecutionReport evaluate(List<PoseFrame> frames) {
    final side = pickVisibleSide(frames);
    final signals = {
      ruleSet.rep.signal,
      for (final c in ruleSet.checks)
        if (!_repMetrics.containsKey(c.signal)) c.signal,
    };
    final samples = extractSignals(frames, side, signals, minConfidence: ruleSet.minConfidence);
    final reps = RepSegmenter(ruleSet.rep).segment(samples);
    final clear = [for (final r in reps) if (r.visibleRatio >= minRepVisibleRatio) r];

    final issues = <ExecutionIssue>[];
    var lostPoints = 0.0;
    for (final check in ruleSet.checks) {
      final highlights = <IssueHighlight>[];
      for (final rep in clear) {
        final measured = _measure(check, rep, samples);
        if (measured != null && !check.passes(measured.value)) {
          highlights.add(IssueHighlight(rep: rep.index, tMs: measured.tMs, value: measured.value));
        }
      }
      if (highlights.isEmpty) continue;
      issues.add(ExecutionIssue(check: check, highlights: highlights));
      lostPoints += check.weight * highlights.length / clear.length;
    }
    issues.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return ExecutionReport(
      exercise: ruleSet.exercise,
      ruleSetVersion: ruleSet.version,
      side: side,
      durationMs: frames.isEmpty ? 0 : frames.last.tMs - frames.first.tMs,
      score: clear.isEmpty ? 0 : (100 - lostPoints).clamp(0, 100).round(),
      reps: reps,
      issues: issues,
      unclearReps: [for (final r in reps) if (r.visibleRatio < minRepVisibleRatio) r.index],
      fatigue: _fatigue(clear),
    );
  }

  ({double value, int tMs})? _measure(RuleCheck check, Rep rep, List<SignalSample> samples) {
    final metric = _repMetrics[check.signal];
    if (metric != null) return (value: metric(rep), tMs: rep.bottomMs);

    ({double value, int tMs})? best;
    for (final s in samples) {
      if (s.tMs < rep.startMs) continue;
      if (s.tMs > rep.endMs) break;
      final v = s[check.signal];
      if (v == null) continue;
      final better = best == null || (check.agg == Aggregation.max ? v > best.value : v < best.value);
      if (better) best = (value: v, tMs: s.tMs);
    }
    return best;
  }

  /// Queda de amplitude: média do último terço vs primeiro terço das reps.
  Fatigue? _fatigue(List<Rep> reps) {
    if (reps.length < 4) return null;
    final third = (reps.length / 3).ceil();
    double mean(Iterable<Rep> rs) => rs.map((r) => r.rangeOfMotion).reduce((a, b) => a + b) / rs.length;
    final first = mean(reps.take(third));
    final last = mean(reps.skip(reps.length - third));
    if (first <= 0) return null;
    final drop = (first - last) / first * 100;
    if (drop < _fatigueDropThresholdPct) return null;
    final from = reps.firstWhere(
      (r) => r.rangeOfMotion < first * (1 - _fatigueDropThresholdPct / 100),
      orElse: () => reps[reps.length - third],
    );
    return Fatigue(romDropPct: drop.round(), fromRep: from.index);
  }
}
