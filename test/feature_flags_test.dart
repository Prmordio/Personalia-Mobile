import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/notifications/fcm_service.dart';
import 'package:personalia_app/core/remote_config/app_remote_config.dart';
import 'package:personalia_app/core/remote_config/feature_flags.dart';
import 'package:personalia_app/features/workout/data/workout_summary.dart';

class _Config implements RemoteConfigValues {
  _Config(this.values);
  final Map<String, String> values;
  @override
  String getString(String key) => values[key] ?? '';
}

void main() {
  test('only an explicit false turns a feature off', () {
    expect(parseFlag('false'), false);
    expect(parseFlag(' FALSE '), false);
    expect(parseFlag('true'), true);
    expect(parseFlag(''), true);
    expect(parseFlag('garbage'), true);
  });

  test('flags default to the current behaviour without Remote Config', () {
    final flags = FeatureFlags.from(_Config({}));
    expect(flags.assistantEnabled, true);
    expect(flags.executionAnalysisEnabled, true);
    expect(flags.maintenanceFor('pt'), isNull);
    final off = FeatureFlags.from(
      _Config({
        RemoteConfigKeys.assistantEnabled: 'false',
        RemoteConfigKeys.executionAnalysisEnabled: 'false',
      }),
    );
    expect(off.assistantEnabled, false);
    expect(off.executionAnalysisEnabled, false);
  });

  test('maintenance message accepts plain text or per-language JSON', () {
    expect(maintenanceText('', 'pt'), isNull);
    expect(maintenanceText(' Instável ', 'en'), 'Instável');
    const json = '{"pt": "Instável", "en": "Unstable"}';
    expect(maintenanceText(json, 'en'), 'Unstable');
    expect(maintenanceText(json, 'es'), 'Instável');
    expect(maintenanceText('{broken', 'pt'), isNull);
  });

  test('push campaigns are a closed set', () {
    expect(FcmService.pushCampaign('weekly_summary'), 'weekly_summary');
    expect(
      FcmService.pushCampaign('subscription_funnel_nudge_choice'),
      'subscription_funnel',
    );
    expect(FcmService.pushCampaign('anything'), 'other');
    expect(FcmService.pushCampaign(null), 'none');
    expect(FcmService.routeForType('medidas_regua'), '/reports/body');
    expect(FcmService.routeForType(null), '/home');
  });

  test('workout duration is reported as a coarse bucket', () {
    WorkoutSummary summary(int minutes) {
      final start = DateTime(2026, 11, 20, 10);
      return WorkoutSummary(
        dayName: 'A',
        startedAt: start,
        finishedAt: start.add(Duration(minutes: minutes)),
        exercises: const [],
      );
    }

    expect(summary(15).durationBucket, 'lt_20');
    expect(summary(20).durationBucket, '20_40');
    expect(summary(59).durationBucket, '40_60');
    expect(summary(90).durationBucket, 'gte_60');
  });
}
