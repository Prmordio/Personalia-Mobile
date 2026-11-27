import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/telemetry/app_telemetry.dart';

void main() {
  test('screen names never include query strings or dynamic identifiers', () {
    expect(
      AppTelemetry.screenName('/assistant?machine=1&token=secret'),
      '/assistant',
    );
    expect(AppTelemetry.screenName('/users/private-id'), 'other');
  });

  test('every routed screen has a name (execution analysis was "other")', () {
    expect(
      AppTelemetry.screenName('/workout/execution-analysis'),
      '/workout/execution-analysis',
    );
  });

  test('event params only carry strings and numbers within Analytics limits', () {
    final clean = AppTelemetry.sanitizeParams({
      'method': 'password',
      'linked': true,
      'days': 4,
      'missing': null,
      'long': 'x' * 150,
    });
    expect(clean, {
      'method': 'password',
      'linked': 'true',
      'days': 4,
      'long': 'x' * 100,
    });
    expect(
      AppTelemetry.sanitizeParams({for (var i = 0; i < 30; i++) 'p$i': i}),
      hasLength(25),
    );
  });

  test('telemetry does not access Firebase before initialization', () {
    final telemetry = AppTelemetry.instance;
    telemetry.event('login', {'method': 'password'});
    telemetry.screen('/home');
    telemetry.recoverableError(
      Exception('secret'),
      StackTrace.current,
      'test',
      detail: 'detail',
    );
    telemetry.setUser('user-id');
    telemetry.setUserProperty('plan', 'paid');
    telemetry.setKey('workout_active', true);
    telemetry.breadcrumb('nav:/home');
    final trace = telemetry.startTrace('noop');
    trace.stop(attributes: {'outcome': 'ok'});
    trace.stop();
  });
}
