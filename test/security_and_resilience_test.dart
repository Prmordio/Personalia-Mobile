import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/connectivity/connectivity.dart';
import 'package:personalia_app/core/network/api_client.dart';
import 'package:personalia_app/core/network/api_errors.dart';
import 'package:personalia_app/core/security/app_check.dart';

DioException _forbidden(Object? body) => DioException(
  requestOptions: RequestOptions(),
  response: Response(requestOptions: RequestOptions(), statusCode: 403, data: body),
);

void main() {
  group('resolveBaseUrl', () {
    test('release builds refuse a plain-http API', () {
      expect(() => resolveBaseUrl(baseUrl: 'http://api.example.com', release: true), throwsStateError);
    });
    test('release builds accept https', () {
      expect(resolveBaseUrl(baseUrl: 'https://api.example.com', release: true), 'https://api.example.com');
    });
    test('debug builds may use the local http backend', () {
      expect(resolveBaseUrl(baseUrl: 'http://10.0.2.2:3000', release: false), 'http://10.0.2.2:3000');
    });
  });

  group('isSubscriptionRequired', () {
    test('detects the trainer guard body passed through by the gateway', () {
      expect(isSubscriptionRequired(_forbidden({'reason': 'subscription_required', 'message': 'x'})), isTrue);
    });
    test('detects the body when Nest nests it under message', () {
      expect(isSubscriptionRequired(_forbidden({'message': {'reason': 'subscription_required'}})), isTrue);
    });
    test('ignores other 403s and other statuses', () {
      expect(isSubscriptionRequired(_forbidden({'message': 'Forbidden'})), isFalse);
      expect(isSubscriptionRequired(DioException(requestOptions: RequestOptions())), isFalse);
      expect(isSubscriptionRequired(const SubscriptionRequiredException()), isTrue);
    });
  });

  group('AppCheckInterceptor', () {
    Future<RequestOptions> run(AppCheckInterceptor interceptor) async {
      final options = RequestOptions(path: '/app/x');
      final handler = _CapturingHandler();
      await interceptor.onRequest(options, handler);
      expect(handler.forwarded, isTrue, reason: 'request must never be blocked by App Check');
      return options;
    }

    test('attaches the token header', () async {
      final options = await run(AppCheckInterceptor(tokenSource: () async => 'tok'));
      expect(options.headers[appCheckHeader], 'tok');
    });

    test('continues without the header when attestation fails', () async {
      final options = await run(AppCheckInterceptor(tokenSource: () async => throw Exception('no play services')));
      expect(options.headers.containsKey(appCheckHeader), isFalse);
    });

    test('does not hang requests when the token is slow', () async {
      final options = await run(
        AppCheckInterceptor(
          tokenSource: () => Future.delayed(const Duration(seconds: 5), () => 'late'),
          timeout: const Duration(milliseconds: 20),
        ),
      );
      expect(options.headers.containsKey(appCheckHeader), isFalse);
    });
  });

  group('isOfflineResult', () {
    test('offline only when no interface is up', () {
      expect(isOfflineResult([ConnectivityResult.none]), isTrue);
      expect(isOfflineResult([]), isTrue);
      expect(isOfflineResult([ConnectivityResult.wifi]), isFalse);
      expect(isOfflineResult([ConnectivityResult.none, ConnectivityResult.mobile]), isFalse);
    });
  });
}

class _CapturingHandler extends RequestInterceptorHandler {
  bool forwarded = false;
  @override
  void next(RequestOptions requestOptions) => forwarded = true;
}
