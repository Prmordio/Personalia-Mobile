import 'exercise_rule_set.dart';
import 'signals.dart';

class Rep {
  const Rep({
    required this.index,
    required this.startMs,
    required this.bottomMs,
    required this.endMs,
    required this.bottomValue,
    required this.topValue,
    required this.visibleRatio,
  });

  /// 1-based (como o aluno conta).
  final int index;
  final int startMs;
  final int bottomMs;
  final int endMs;

  /// Valor do sinal principal no fundo (ex.: menor ângulo do joelho).
  final double bottomValue;
  final double topValue;

  /// Fração dos quadros da rep em que o sinal principal estava visível.
  final double visibleRatio;

  int get eccentricMs => bottomMs - startMs;
  int get concentricMs => endMs - bottomMs;
  double get rangeOfMotion => (topValue - bottomValue).abs();

  bool containsMs(int tMs) => tMs >= startMs && tMs <= endMs;

  Map<String, dynamic> toJson() => {
        'index': index,
        'startMs': startMs,
        'bottomMs': bottomMs,
        'endMs': endMs,
        'bottom': double.parse(bottomValue.toStringAsFixed(1)),
        'eccentricMs': eccentricMs,
        'concentricMs': concentricMs,
      };
}

/// Conta reps por histerese no sinal principal: topo (≥ up) → desce abaixo de `down` →
/// volta acima de `up`. A faixa entre down/up evita que tremidas virem reps extras.
/// Pensado para movimentos que "descem" o sinal (agachamento: ângulo do joelho).
class RepSegmenter {
  const RepSegmenter(this.rule);
  final RepRule rule;

  List<Rep> segment(List<SignalSample> samples) {
    final reps = <Rep>[];
    var inRep = false;
    int? lastTopMs;
    double lastTopValue = rule.up;
    late int startMs;
    late double startTopValue;
    var bottomValue = double.infinity;
    var bottomMs = 0;
    var total = 0, visible = 0;

    for (final s in samples) {
      final v = s[rule.signal];
      if (inRep) {
        total++;
        if (v != null) visible++;
      }
      if (v == null) continue;

      if (!inRep) {
        if (v >= rule.up) {
          lastTopMs = s.tMs;
          lastTopValue = v;
        } else if (v < rule.down && lastTopMs != null) {
          inRep = true;
          startMs = lastTopMs;
          startTopValue = lastTopValue;
          bottomValue = v;
          bottomMs = s.tMs;
          total = 1;
          visible = 1;
        }
        continue;
      }

      if (v < bottomValue) {
        bottomValue = v;
        bottomMs = s.tMs;
      }
      if (v >= rule.up) {
        if (s.tMs - startMs >= rule.minDurationMs) {
          reps.add(Rep(
            index: reps.length + 1,
            startMs: startMs,
            bottomMs: bottomMs,
            endMs: s.tMs,
            bottomValue: bottomValue,
            topValue: startTopValue,
            visibleRatio: total == 0 ? 0 : visible / total,
          ));
        }
        inRep = false;
        lastTopMs = s.tMs;
        lastTopValue = v;
      }
    }
    return reps;
  }
}
