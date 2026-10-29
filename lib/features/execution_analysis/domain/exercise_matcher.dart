/// Mapeia o nome livre do exercício no treino (gerado pela IA, pt/en/es) para o rule set.
/// Variações com cinemática diferente (unilaterais, sumô, máquina hack, saltos) ficam de
/// fora até terem regras próprias.
String? matchExecutionRuleSet(String exerciseName) {
  final name = _normalize(exerciseName);
  if (!_squat.hasMatch(name) || _squatExcluded.hasMatch(name)) return null;
  return 'squat';
}

final _squat = RegExp(r'\b(agachamento|squat|sentadilla)\b');
final _squatExcluded = RegExp(r'\b(bulgar\w*|sumo|hack|pistol|afundo|lunge|zancada|salto|jump|split|unilateral|cossack)\b');

String _normalize(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  final lower = s.toLowerCase();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}
