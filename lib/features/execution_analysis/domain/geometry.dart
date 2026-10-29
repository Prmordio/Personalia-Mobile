import 'dart:math' as math;

import 'pose_frame.dart';

/// Ângulo (graus, 0..180) no vértice [b] formado por a-b-c.
double angleAt(PosePoint a, PosePoint b, PosePoint c) {
  final v1x = a.x - b.x, v1y = a.y - b.y;
  final v2x = c.x - b.x, v2y = c.y - b.y;
  final n = math.sqrt(v1x * v1x + v1y * v1y) * math.sqrt(v2x * v2x + v2y * v2y);
  if (n == 0) return 180;
  final cos = ((v1x * v2x + v1y * v2y) / n).clamp(-1.0, 1.0);
  return math.acos(cos) * 180 / math.pi;
}

/// Inclinação (graus, 0..180) do segmento bottom→top em relação à vertical para cima.
double angleFromVertical(PosePoint top, PosePoint bottom) {
  final dx = top.x - bottom.x, dy = top.y - bottom.y;
  return math.atan2(dx.abs(), -dy) * 180 / math.pi;
}

double distance(PosePoint a, PosePoint b) => math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// Lado mais visível para a câmera (vista lateral): maior confiança média na cadeia
/// ombro-quadril-joelho-tornozelo.
BodySide pickVisibleSide(List<PoseFrame> frames) {
  const chain = [Joint.shoulder, Joint.hip, Joint.knee, Joint.ankle];
  double score(BodySide side) {
    var sum = 0.0;
    for (final f in frames) {
      for (final j in chain) {
        sum += f.points[j.on(side)]?.confidence ?? 0;
      }
    }
    return sum;
  }

  return score(BodySide.left) >= score(BodySide.right) ? BodySide.left : BodySide.right;
}

/// Filtro One-Euro (Casiez et al.): suaviza jitter do pose sem atrasar movimentos rápidos.
class OneEuroFilter {
  OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.05, this.dCutoff = 1.0});

  final double minCutoff;
  final double beta;
  final double dCutoff;

  double? _x;
  double _dx = 0;
  int? _tMs;

  double filter(double value, int tMs) {
    final prevT = _tMs;
    final prevX = _x;
    _tMs = tMs;
    if (prevX == null || prevT == null || tMs <= prevT) {
      _x = value;
      return value;
    }
    final dt = (tMs - prevT) / 1000.0;
    final dx = (value - prevX) / dt;
    _dx = _lowPass(_dx, dx, _alpha(dCutoff, dt));
    final cutoff = minCutoff + beta * _dx.abs();
    _x = _lowPass(prevX, value, _alpha(cutoff, dt));
    return _x!;
  }

  static double _alpha(double cutoff, double dt) {
    final tau = 1 / (2 * math.pi * cutoff);
    return 1 / (1 + tau / dt);
  }

  static double _lowPass(double prev, double value, double alpha) => prev + alpha * (value - prev);
}
