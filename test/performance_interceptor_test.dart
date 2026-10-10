import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/telemetry/performance_interceptor.dart';

class _Metric implements HttpMetric {
  int stops = 0;
  @override
  int? httpResponseCode;
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);
  final int status;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', status);
  @override
  void close({bool force = false}) {}
}

void main() {
  test('network URL removes credentials, queries, fragments and identifiers', () {
    expect(
      PerformanceInterceptor.sanitizedUrl(
        Uri.parse(
          'https://user:secret@api.test/app/workout/private-id?token=secret#private',
        ),
      ),
      'https://api.test/app/workout/_',
    );
  });
  for (final status in [200, 500]) {
    test('metric stops once and records HTTP $status', () async {
      final metric = _Metric();
      final dio = Dio()..httpClientAdapter = _Adapter(status);
      dio.interceptors.add(
        PerformanceInterceptor(factory: (_) async => metric),
      );
      if (status == 200) {
        expect((await dio.get('https://api.test/app/workout')).statusCode, 200);
      } else {
        await expectLater(
          dio.get('https://api.test/app/workout'),
          throwsA(isA<DioException>()),
        );
      }
      expect(metric.httpResponseCode, status);
      expect(metric.stops, 1);
      dio.close();
    });
  }
  test(
    'a failed metrics provider does not prevent a successful request',
    () async {
      final dio = Dio()..httpClientAdapter = _Adapter(200);
      dio.interceptors.add(
        PerformanceInterceptor(
          factory: (_) async => throw StateError('SDK unavailable'),
        ),
      );
      expect((await dio.get('https://api.test/app/workout')).statusCode, 200);
      dio.close();
    },
  );
}
