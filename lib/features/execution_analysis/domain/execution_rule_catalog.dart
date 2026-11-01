import 'exercise_rule_set.dart';
import 'rule_engine.dart';

/// Regras publicadas + quais nomes de exercício usam cada uma. O nome do exercício no treino é
/// texto livre (gerado pela IA); só casa se o painel ligou aquele nome à regra — nada de
/// adivinhar por palavra-chave.
class ExecutionRuleCatalog {
  ExecutionRuleCatalog(Iterable<ExerciseRuleSet> ruleSets) {
    for (final ruleSet in ruleSets.where(isSupportedRuleSet)) {
      _byKey[ruleSet.exercise] = ruleSet;
      for (final name in ruleSet.exerciseNames) {
        _keyByName[normalizeExerciseName(name)] = ruleSet.exercise;
      }
    }
  }

  /// Regra que este app não sabe ler (articulação/campo de uma versão mais nova) é descartada
  /// sozinha — não pode derrubar o catálogo inteiro.
  factory ExecutionRuleCatalog.fromJson(Map<String, dynamic> json) => ExecutionRuleCatalog([
        for (final r in json['ruleSets'] as List? ?? const []) ?_tryParse(r),
      ]);

  static final empty = ExecutionRuleCatalog(const []);

  final Map<String, ExerciseRuleSet> _byKey = {};
  final Map<String, String> _keyByName = {};

  bool get isEmpty => _byKey.isEmpty;

  /// Chave da regra ligada ao nome do exercício, ou null se ele não tem análise.
  String? match(String exerciseName) => _keyByName[normalizeExerciseName(exerciseName)];

  ExerciseRuleSet? ruleSet(String exerciseKey) => _byKey[exerciseKey];
}

/// Regra que esta versão do app consegue aplicar: formato conhecido e só sinais que ele mede.
/// Uma regra publicada para uma versão mais nova do app é ignorada em vez de quebrar a análise.
ExerciseRuleSet? _tryParse(Object? json) {
  try {
    return ExerciseRuleSet.fromJson(json as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

bool isSupportedRuleSet(ExerciseRuleSet ruleSet) =>
    ruleSet.schemaVersion <= supportedRuleSchemaVersion &&
    isSupportedSignal(ruleSet.rep.signal) &&
    ruleSet.checks.every((c) => isSupportedSignal(c.signal));

const _accented = 'áàâãäåéèêëíìîïóòôõöúùûüçñý';
const _plain = 'aaaaaaeeeeiiiiooooouuuucny';

/// Mesma normalização do trainer (`normalizeExerciseName`): minúsculo, sem acento, espaços
/// simples. Mudar aqui exige mudar lá.
String normalizeExerciseName(String name) {
  final buffer = StringBuffer();
  for (final ch in name.toLowerCase().split('')) {
    final i = _accented.indexOf(ch);
    buffer.write(i >= 0 ? _plain[i] : ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
