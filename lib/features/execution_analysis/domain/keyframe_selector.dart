import 'execution_report.dart';

const int maxKeyframes = 12;
const int _minGapMs = 250;

/// Momento do vídeo a extrair como JPEG e enviar à IA, com legenda para o modelo.
class KeyframeRequest {
  const KeyframeRequest({required this.tMs, required this.label});
  final int tMs;
  final String label;
}

/// Escolhe os quadros que importam (em vez do vídeo todo): topo da 1ª rep, fundo da
/// melhor rep e os piores momentos de cada issue. Legendas em inglês — são para o modelo.
List<KeyframeRequest> selectKeyframes(ExecutionReport report) {
  if (!report.hasReps) return const [];
  final picks = <KeyframeRequest>[];

  void add(int tMs, String label) {
    if (picks.length >= maxKeyframes) return;
    if (picks.any((p) => (p.tMs - tMs).abs() < _minGapMs)) return;
    picks.add(KeyframeRequest(tMs: tMs, label: label));
  }

  final first = report.reps.first;
  add(first.startMs, 'rep ${first.index} · top · t=${_s(first.startMs)}');

  final failing = {for (final i in report.issues) ...i.reps};
  final clean = report.reps.where((r) => !failing.contains(r.index) && !report.unclearReps.contains(r.index));
  if (clean.isNotEmpty) {
    final best = clean.reduce((a, b) => a.bottomValue <= b.bottomValue ? a : b);
    add(best.bottomMs, 'rep ${best.index} · bottom · best rep · t=${_s(best.bottomMs)}');
  }

  // Dois piores momentos por issue, intercalando issues para nenhum monopolizar o limite.
  final perIssue = [
    for (final issue in report.issues)
      ([...issue.highlights]..sort(issue.compareWorse))
          .take(2)
          .map((h) => KeyframeRequest(tMs: h.tMs, label: 'rep ${h.rep} · ${issue.id} · t=${_s(h.tMs)}'))
          .toList(),
  ];
  for (var round = 0; round < 2; round++) {
    for (final list in perIssue) {
      if (round < list.length) add(list[round].tMs, list[round].label);
    }
  }

  // Completa com fundos de outras reps (distribuídos) para dar contexto ao modelo.
  for (final rep in report.reps) {
    add(rep.bottomMs, 'rep ${rep.index} · bottom · t=${_s(rep.bottomMs)}');
  }

  return picks..sort((a, b) => a.tMs.compareTo(b.tMs));
}

String _s(int ms) => '${(ms / 1000).toStringAsFixed(1)}s';
