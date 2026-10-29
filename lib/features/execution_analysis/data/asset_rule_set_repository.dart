import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/exercise_rule_set.dart';

/// Rule sets empacotados no app (`assets/execution_rules/<exercise>.json`).
class AssetRuleSetRepository implements RuleSetRepository {
  AssetRuleSetRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final Map<String, ExerciseRuleSet> _cache = {};

  @override
  Future<ExerciseRuleSet> load(String exerciseKey) async {
    final cached = _cache[exerciseKey];
    if (cached != null) return cached;
    final raw = await _bundle.loadString('assets/execution_rules/$exerciseKey.json');
    return _cache[exerciseKey] = ExerciseRuleSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
