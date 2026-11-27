import 'package:dio/dio.dart';

import 'app_telemetry.dart';
import 'performance_interceptor.dart';

typedef HttpErrorSink =
    void Function(
      Object error,
      StackTrace stack,
      String operation, {
      String? detail,
    });

/// Reports server failures (5xx) and timeouts as Crashlytics non-fatals grouped by
/// sanitized endpoint, e.g. `http_5xx GET /app/workout/_`. Expected 4xx (validation,
/// expired session) and offline errors only leave a breadcrumb. The same category is
/// reported at most once per [throttle] to avoid flooding during an outage.
class HttpErrorInterceptor extends Interceptor {
  HttpErrorInterceptor({
    HttpErrorSink? report,
    void Function(String message)? breadcrumb,
    DateTime Function()? now,
    this.throttle = const Duration(minutes: 5),
  }) : _report = report ?? AppTelemetry.instance.recoverableError,
       _breadcrumb = breadcrumb ?? AppTelemetry.instance.breadcrumb,
       _now = now ?? DateTime.now;

  final HttpErrorSink _report;
  final void Function(String message) _breadcrumb;
  final DateTime Function() _now;
  final Duration throttle;
  final _lastReported = <String, DateTime>{};

  static String endpoint(RequestOptions options) =>
      '${options.method.toUpperCase()} '
      '${Uri.parse(PerformanceInterceptor.sanitizedUrl(options.uri)).path}';

  static String? category(DioException err) {
    final status = err.response?.statusCode;
    if (status != null && status >= 500) return 'http_5xx';
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'http_timeout',
      _ => null,
    };
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      final target = endpoint(err.requestOptions);
      final status = err.response?.statusCode;
      _breadcrumb('http ${status ?? err.type.name} $target');
      final kind = category(err);
      if (kind != null) {
        final operation = '$kind $target';
        final now = _now();
        final last = _lastReported[operation];
        if (last == null || now.difference(last) >= throttle) {
          _lastReported[operation] = now;
          _report(
            err,
            err.stackTrace,
            operation,
            detail: status == null ? err.type.name : 'status=$status',
          );
        }
      }
    } catch (_) {}
    handler.next(err);
  }
}
