import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/telemetry/http_error_interceptor.dart';

class _Handler extends ErrorInterceptorHandler {
  int forwarded = 0;
  @override
  void next(DioException err) => forwarded++;
}

DioException _error({int? status, DioExceptionType? type}) {
  final options = RequestOptions(
    path: 'https://api.test/app/workout/abc-123?token=secret',
    method: 'get',
  );
  return DioException(
    requestOptions: options,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
    type: type ?? DioExceptionType.badResponse,
  );
}

void main() {
  late List<(String, String?)> reports;
  late List<String> crumbs;
  late DateTime now;
  late HttpErrorInterceptor interceptor;

  setUp(() {
    reports = [];
    crumbs = [];
    now = DateTime(2026, 11, 20, 10);
    interceptor = HttpErrorInterceptor(
      report: (_, _, operation, {detail}) => reports.add((operation, detail)),
      breadcrumb: crumbs.add,
      now: () => now,
    );
  });

  test('reports 5xx grouped by sanitized endpoint, without ids or query', () {
    final handler = _Handler();
    interceptor.onError(_error(status: 503), handler);
    expect(reports, [('http_5xx GET /app/workout/_', 'status=503')]);
    expect(crumbs, ['http 503 GET /app/workout/_']);
    expect(handler.forwarded, 1);
  });

  test('reports timeouts but only breadcrumbs expected 4xx and offline', () {
    interceptor.onError(
      _error(type: DioExceptionType.receiveTimeout),
      _Handler(),
    );
    interceptor.onError(_error(status: 401), _Handler());
    interceptor.onError(
      _error(type: DioExceptionType.connectionError),
      _Handler(),
    );
    expect(reports, [('http_timeout GET /app/workout/_', 'receiveTimeout')]);
    expect(crumbs, hasLength(3));
  });

  test('throttles the same failure during an outage', () {
    interceptor.onError(_error(status: 500), _Handler());
    now = now.add(const Duration(minutes: 1));
    interceptor.onError(_error(status: 502), _Handler());
    expect(reports, hasLength(1));
    now = now.add(const Duration(minutes: 5));
    interceptor.onError(_error(status: 500), _Handler());
    expect(reports, hasLength(2));
  });
}
