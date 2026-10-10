import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'app_telemetry.dart';

typedef MetricFactory = Future<HttpMetric?> Function(RequestOptions options);

class PerformanceInterceptor extends Interceptor {
  PerformanceInterceptor({MetricFactory? factory})
    : _factory = factory ?? _start;
  final MetricFactory _factory;
  static const _key = 'personalia.performance.metric';

  static String sanitizedUrl(Uri uri) {
    const allowed = {
      'app',
      'auth',
      'login',
      'logout',
      'otp',
      'request',
      'verify',
      'password',
      'onboarding',
      'status',
      'profile',
      'preferences',
      'workout',
      'workouts',
      'current',
      'today',
      'last',
      'generate',
      'log',
      'reports',
      'body',
      'volume',
      'frequency',
      'load-evolution',
      'assistant',
      'device-token',
      'biometric',
      'register',
      'remove',
      'access',
      'email',
      'phone',
      'reset',
      'complete',
    };
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      pathSegments: uri.pathSegments.map((s) => allowed.contains(s) ? s : '_'),
    ).toString();
  }

  static Future<HttpMetric?> _start(RequestOptions options) async {
    if (!AppTelemetry.instance.enabled ||
        options.responseType == ResponseType.stream) {
      return null;
    }
    final methods = {
      'GET': HttpMethod.Get,
      'POST': HttpMethod.Post,
      'PUT': HttpMethod.Put,
      'PATCH': HttpMethod.Patch,
      'DELETE': HttpMethod.Delete,
      'HEAD': HttpMethod.Head,
      'OPTIONS': HttpMethod.Options,
    };
    final method = methods[options.method.toUpperCase()];
    if (method == null) return null;
    final metric = FirebasePerformance.instance.newHttpMetric(
      sanitizedUrl(options.uri),
      method,
    );
    await metric.start();
    return metric;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra.remove(_key);
    try {
      final metric = await _factory(options);
      if (metric != null) options.extra[_key] = metric;
    } catch (_) {}
    handler.next(options);
  }

  Future<void> _stop(
    RequestOptions options,
    Response<dynamic>? response,
  ) async {
    final metric = options.extra.remove(_key) as HttpMetric?;
    if (metric == null) return;
    try {
      metric.httpResponseCode = response?.statusCode;
      await metric.stop();
    } catch (_) {}
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    await _stop(response.requestOptions, response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    await _stop(err.requestOptions, err.response);
    handler.next(err);
  }
}
