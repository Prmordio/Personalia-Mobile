/// Landmarks do BlazePose usados na análise (vista lateral). Subconjunto dos 33.
enum Landmark {
  leftShoulder,
  rightShoulder,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

enum BodySide { left, right }

/// Articulação independente de lado — é o que rule sets e overlay referenciam.
enum Joint { shoulder, hip, knee, ankle, heel, footIndex }

extension JointSide on Joint {
  Landmark on(BodySide side) => switch (this) {
        Joint.shoulder => side == BodySide.left ? Landmark.leftShoulder : Landmark.rightShoulder,
        Joint.hip => side == BodySide.left ? Landmark.leftHip : Landmark.rightHip,
        Joint.knee => side == BodySide.left ? Landmark.leftKnee : Landmark.rightKnee,
        Joint.ankle => side == BodySide.left ? Landmark.leftAnkle : Landmark.rightAnkle,
        Joint.heel => side == BodySide.left ? Landmark.leftHeel : Landmark.rightHeel,
        Joint.footIndex => side == BodySide.left ? Landmark.leftFootIndex : Landmark.rightFootIndex,
      };
}

/// Ponto normalizado (0..1) no quadro em pé (já rotacionado), y cresce para baixo.
class PosePoint {
  const PosePoint(this.x, this.y, this.confidence);
  final double x;
  final double y;
  final double confidence;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'c': confidence};
  factory PosePoint.fromJson(Map<String, dynamic> json) => PosePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['c'] as num).toDouble(),
      );
}

class PoseFrame {
  const PoseFrame(this.tMs, this.points);

  /// Instante relativo ao início do vídeo gravado.
  final int tMs;
  final Map<Landmark, PosePoint> points;

  PosePoint? visible(Landmark landmark, double minConfidence) {
    final p = points[landmark];
    return p != null && p.confidence >= minConfidence ? p : null;
  }

  Map<String, dynamic> toJson() => {
        't': tMs,
        'p': {for (final e in points.entries) e.key.name: e.value.toJson()},
      };

  factory PoseFrame.fromJson(Map<String, dynamic> json) => PoseFrame(
        json['t'] as int,
        {
          for (final e in (json['p'] as Map<String, dynamic>).entries)
            Landmark.values.byName(e.key): PosePoint.fromJson(e.value as Map<String, dynamic>),
        },
      );
}
