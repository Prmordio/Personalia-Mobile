import 'geometry.dart';
import 'pose_frame.dart';

/// Valores de um quadro por sinal; `null` = landmarks sem confiança suficiente.
class SignalSample {
  const SignalSample(this.tMs, this.values);
  final int tMs;
  final Map<String, double?> values;

  double? operator [](String signal) => values[signal];
}

typedef _SignalFn = double? Function(PoseFrame frame, BodySide side, double minConfidence);

/// Sinais por quadro que os rule sets podem referenciar. Adicionar um sinal aqui o
/// disponibiliza para qualquer exercício.
final Map<String, _SignalFn> _signals = {
  'knee_angle': (f, s, c) => _angle(f, s, c, Joint.hip, Joint.knee, Joint.ankle),
  'hip_angle': (f, s, c) => _angle(f, s, c, Joint.shoulder, Joint.hip, Joint.knee),
  // Braço estendido ≈ 180°, dobrado (rosca no topo) ≈ 40°.
  'elbow_angle': (f, s, c) => _angle(f, s, c, Joint.shoulder, Joint.elbow, Joint.wrist),
  // Braço junto ao tronco ≈ 0–20°, na horizontal ≈ 90°, acima da cabeça ≈ 170°.
  'shoulder_angle': (f, s, c) => _angle(f, s, c, Joint.hip, Joint.shoulder, Joint.elbow),
  // Canela × pé: em pé ≈ 90–110°, na ponta do pé (panturrilha) ≈ 130–150°.
  'ankle_angle': (f, s, c) => _angle(f, s, c, Joint.knee, Joint.ankle, Joint.footIndex),
  'trunk_lean': (f, s, c) {
    final shoulder = f.visible(Joint.shoulder.on(s), c);
    final hip = f.visible(Joint.hip.on(s), c);
    return shoulder == null || hip == null ? null : angleFromVertical(shoulder, hip);
  },
  // Altura do calcanhar acima da ponta do pé, em % do comprimento da canela (bruto; a
  // linha de base é descontada em extractSignals para anular a inclinação da câmera).
  'heel_lift': (f, s, c) {
    final heel = f.visible(Joint.heel.on(s), c);
    final toe = f.visible(Joint.footIndex.on(s), c);
    final knee = f.visible(Joint.knee.on(s), c);
    final ankle = f.visible(Joint.ankle.on(s), c);
    if (heel == null || toe == null || knee == null || ankle == null) return null;
    final shin = distance(knee, ankle);
    return shin == 0 ? null : (toe.y - heel.y) / shin * 100;
  },
};

/// Articulações de que cada sinal depende — definem o lado escolhido e o enquadramento
/// exigido antes de gravar (um supino não precisa do tornozelo visível).
const signalJoints = {
  'knee_angle': [Joint.hip, Joint.knee, Joint.ankle],
  'hip_angle': [Joint.shoulder, Joint.hip, Joint.knee],
  'elbow_angle': [Joint.shoulder, Joint.elbow, Joint.wrist],
  'shoulder_angle': [Joint.hip, Joint.shoulder, Joint.elbow],
  'ankle_angle': [Joint.knee, Joint.ankle, Joint.footIndex],
  'trunk_lean': [Joint.shoulder, Joint.hip],
  'heel_lift': [Joint.knee, Joint.ankle, Joint.heel, Joint.footIndex],
};

const _baselineSignals = {'heel_lift'};
const _baselineSamples = 10;

double? _angle(PoseFrame f, BodySide side, double minConfidence, Joint a, Joint b, Joint c) {
  final pa = f.visible(a.on(side), minConfidence);
  final pb = f.visible(b.on(side), minConfidence);
  final pc = f.visible(c.on(side), minConfidence);
  return pa == null || pb == null || pc == null ? null : angleAt(pa, pb, pc);
}

bool isKnownSignal(String signal) => _signals.containsKey(signal);

/// Extrai e suaviza (One-Euro) os [signals] de cada quadro no lado [side].
List<SignalSample> extractSignals(
  List<PoseFrame> frames,
  BodySide side,
  Set<String> signals, {
  required double minConfidence,
}) {
  final filters = {for (final s in signals) s: OneEuroFilter()};
  final raw = <SignalSample>[];
  for (final frame in frames) {
    raw.add(SignalSample(frame.tMs, {
      for (final s in signals)
        s: switch (_signals[s]?.call(frame, side, minConfidence)) {
          null => null,
          final v => filters[s]!.filter(v, frame.tMs),
        },
    }));
  }

  for (final s in signals.intersection(_baselineSignals)) {
    final firsts = raw.map((r) => r[s]).whereType<double>().take(_baselineSamples).toList()..sort();
    if (firsts.isEmpty) continue;
    final baseline = firsts[firsts.length ~/ 2];
    for (final r in raw) {
      final v = r.values[s];
      if (v != null) r.values[s] = v - baseline;
    }
  }
  return raw;
}
