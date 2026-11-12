import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/exercise_rule_set.dart';
import '../domain/execution_rule_catalog.dart';

/// Guarda o último catálogo recebido para a análise funcionar sem rede.
abstract interface class RuleCatalogCache {
  Future<String?> read();
  Future<void> write(String json);
}

class FileRuleCatalogCache implements RuleCatalogCache {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/execution_rules_catalog.json');

  @override
  Future<String?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String json) async => (await _file()).writeAsString(json);
}

/// Regras publicadas no painel (`GET /app/execution-rules`). Busca uma vez por sessão do app;
/// sem rede usa o último catálogo salvo e, sem nenhum, fica vazio (nenhum exercício analisável).
class RemoteRuleSetRepository implements RuleSetRepository {
  RemoteRuleSetRepository(this._dio, {RuleCatalogCache? cache}) : _cache = cache ?? FileRuleCatalogCache();
  final Dio _dio;
  final RuleCatalogCache _cache;
  Future<ExecutionRuleCatalog>? _catalog;

  @override
  Future<ExecutionRuleCatalog> catalog() => _catalog ??= _load();

  @override
  Future<ExerciseRuleSet> load(String exerciseKey) async {
    final ruleSet = (await catalog()).ruleSet(exerciseKey);
    if (ruleSet == null) throw StateError('Regra de execução "$exerciseKey" não está disponível.');
    return ruleSet;
  }

  Future<ExecutionRuleCatalog> _load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/app/execution-rules');
      final data = response.data ?? const {};
      final catalog = ExecutionRuleCatalog.fromJson(data);
      await _cache.write(jsonEncode(data)).catchError((Object e) => debugPrint('rule catalog cache write failed: $e'));
      return catalog;
    } catch (e) {
      debugPrint('execution rules fetch failed, using cache: $e');
      // Não memoriza a falha: a próxima chamada tenta buscar de novo.
      _catalog = null;
      return _fromCache();
    }
  }

  Future<ExecutionRuleCatalog> _fromCache() async {
    try {
      final raw = await _cache.read();
      return raw == null ? ExecutionRuleCatalog.empty : ExecutionRuleCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('rule catalog cache read failed: $e');
      return ExecutionRuleCatalog.empty;
    }
  }
}
