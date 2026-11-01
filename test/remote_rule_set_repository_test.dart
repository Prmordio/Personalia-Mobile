import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/execution_analysis/data/remote_rule_set_repository.dart';

Map<String, dynamic> _catalogJson() => {
      'ruleSets': [jsonDecode(File('test/fixtures/execution_rules/squat.json').readAsStringSync())],
    };

class _MemoryCache implements RuleCatalogCache {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String json) async => value = json;
}

/// Responde `/app/execution-rules` com [body], ou falha como sem rede quando [body] é null.
Dio _dio(Map<String, dynamic>? body, {List<String>? calls}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    calls?.add(options.path);
    if (body == null) {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
    } else {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: body));
    }
  }));
  return dio;
}

void main() {
  test('should_fetch_published_rules_once_and_cache_them', () async {
    final cache = _MemoryCache();
    final calls = <String>[];
    final repository = RemoteRuleSetRepository(_dio(_catalogJson(), calls: calls), cache: cache);

    final catalog = await repository.catalog();
    await repository.load('squat');

    expect(catalog.match('Agachamento Livre'), 'squat');
    expect(calls, ['/app/execution-rules']);
    expect(cache.value, isNotNull);
  });

  test('should_use_the_last_cached_catalog_when_offline', () async {
    final cache = _MemoryCache()..value = jsonEncode(_catalogJson());
    final repository = RemoteRuleSetRepository(_dio(null), cache: cache);

    expect((await repository.catalog()).match('agachamento livre'), 'squat');
  });

  test('should_have_no_analyzable_exercise_when_offline_without_cache', () async {
    final repository = RemoteRuleSetRepository(_dio(null), cache: _MemoryCache());

    expect((await repository.catalog()).isEmpty, isTrue);
    expect(() => repository.load('squat'), throwsStateError);
  });
}
