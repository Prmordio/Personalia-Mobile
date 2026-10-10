import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/telemetry/app_telemetry.dart';

void main() {
  test('screen names never include query strings or dynamic identifiers', () {
    expect(
      AppTelemetry.screenName('/assistant?machine=1&token=secret'),
      '/assistant',
    );
    expect(AppTelemetry.screenName('/coming-soon/private-id'), '/coming-soon');
    expect(AppTelemetry.screenName('/users/private-id'), 'other');
  });

  test('telemetry does not access Firebase before initialization', () {
    AppTelemetry.instance.event('login');
    AppTelemetry.instance.screen('/home');
    AppTelemetry.instance.recoverableError(
      Exception('secret'),
      StackTrace.current,
      'test',
    );
  });
}
