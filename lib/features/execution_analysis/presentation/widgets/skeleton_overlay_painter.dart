import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/geometry.dart';
import '../../domain/pose_frame.dart';

/// Ângulo a desenhar no vértice, com linha fantasma da posição alvo (ex.: joelho no fundo).
class AngleAnnotation {
  const AngleAnnotation({required this.vertex, required this.fixedArm, required this.movingArm, this.target});
  final Joint vertex;

  /// Segmento de referência (ex.: canela, joelho→tornozelo).
  final Joint fixedArm;

  /// Segmento que deveria se mover até o alvo (ex.: coxa, joelho→quadril).
  final Joint movingArm;
  final double? target;
}

const _bones = [
  (Joint.shoulder, Joint.hip),
  (Joint.hip, Joint.knee),
  (Joint.knee, Joint.ankle),
  (Joint.ankle, Joint.heel),
  (Joint.heel, Joint.footIndex),
  (Joint.ankle, Joint.footIndex),
];

const okColor = Color(0xFF3DDC84);
const alertColor = Color(0xFFFF4D4F);
const _ghostColor = Color(0xCCFFFFFF);

/// Esqueleto do lado visível sobre o vídeo/preview. Coordenadas normalizadas (0..1) do
/// quadro em pé, então basta escalar para o tamanho do widget (mesmo aspect ratio).
class SkeletonOverlayPainter extends CustomPainter {
  SkeletonOverlayPainter({
    required this.frame,
    required this.side,
    this.alertJoints = const {},
    this.annotation,
    this.minConfidence = 0.5,
    this.mirror = false,
  });

  final PoseFrame? frame;
  final BodySide side;
  final Set<Joint> alertJoints;
  final AngleAnnotation? annotation;
  final double minConfidence;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f == null) return;

    Offset? at(Joint j) {
      final p = f.visible(j.on(side), minConfidence);
      if (p == null) return null;
      return Offset((mirror ? 1 - p.x : p.x) * size.width, p.y * size.height);
    }

    final scale = size.shortestSide / 400;
    final bone = Paint()
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in _bones) {
      final pa = at(a), pb = at(b);
      if (pa == null || pb == null) continue;
      bone.color = (alertJoints.contains(a) && alertJoints.contains(b) ? alertColor : okColor).withValues(alpha: 0.85);
      canvas.drawLine(pa, pb, bone);
    }

    for (final j in Joint.values) {
      final p = at(j);
      if (p == null) continue;
      final alert = alertJoints.contains(j);
      canvas.drawCircle(p, (alert ? 8 : 5) * scale, Paint()..color = alert ? alertColor : okColor);
      canvas.drawCircle(
        p,
        (alert ? 8 : 5) * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale
          ..color = Colors.white,
      );
    }

    final ann = annotation;
    if (ann != null) _paintAngle(canvas, ann, at(ann.vertex), at(ann.fixedArm), at(ann.movingArm), scale);
  }

  void _paintAngle(Canvas canvas, AngleAnnotation ann, Offset? v, Offset? fixed, Offset? moving, double scale) {
    if (v == null || fixed == null || moving == null) return;
    final angle = angleAt(_pt(moving), _pt(v), _pt(fixed));
    final fixedDir = math.atan2(fixed.dy - v.dy, fixed.dx - v.dx);
    final movingDir = math.atan2(moving.dy - v.dy, moving.dx - v.dx);
    var sweep = movingDir - fixedDir;
    while (sweep > math.pi) {
      sweep -= 2 * math.pi;
    }
    while (sweep < -math.pi) {
      sweep += 2 * math.pi;
    }

    final radius = 28 * scale;
    canvas.drawArc(
      Rect.fromCircle(center: v, radius: radius),
      fixedDir,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..color = alertColor,
    );

    final target = ann.target;
    if (target != null) {
      // Coxa "ideal": o segmento fixo girado pelo ângulo alvo, no mesmo sentido do real.
      final targetDir = fixedDir + sweep.sign * target * math.pi / 180;
      final length = (moving - v).distance;
      _dashedLine(canvas, v, v + Offset(math.cos(targetDir), math.sin(targetDir)) * length, scale);
    }

    final label = TextPainter(
      text: TextSpan(
        text: '${angle.round()}°',
        style: TextStyle(color: Colors.white, fontSize: 15 * scale, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final mid = fixedDir + sweep / 2;
    final anchor = v + Offset(math.cos(mid), math.sin(mid)) * (radius + 18 * scale);
    final box = Rect.fromCenter(center: anchor, width: label.width + 10 * scale, height: label.height + 4 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(box, Radius.circular(6 * scale)), Paint()..color = alertColor);
    label.paint(canvas, box.topLeft + Offset(5 * scale, 2 * scale));
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, double scale) {
    final paint = Paint()
      ..color = _ghostColor
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    final dash = 8 * scale, gap = 6 * scale;
    for (var d = 0.0; d < total; d += dash + gap) {
      canvas.drawLine(from + dir * d, from + dir * math.min(d + dash, total), paint);
    }
  }

  static PosePoint _pt(Offset o) => PosePoint(o.dx, o.dy, 1);

  @override
  bool shouldRepaint(SkeletonOverlayPainter old) =>
      old.frame != frame || old.alertJoints != alertJoints || old.annotation != annotation || old.side != side;
}

/// Quadro mais próximo de [tMs] (frames ordenados por tempo) — busca binária.
PoseFrame? frameAt(List<PoseFrame> frames, int tMs) {
  if (frames.isEmpty) return null;
  var lo = 0, hi = frames.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (frames[mid].tMs < tMs) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (lo > 0 && (tMs - frames[lo - 1].tMs).abs() < (frames[lo].tMs - tMs).abs()) lo--;
  return frames[lo];
}
