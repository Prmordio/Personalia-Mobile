import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/telemetry/user_telemetry_sync.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/onboarding/data/onboarding_api.dart';

String _jwt(Map<String, Object> claims) =>
    'h.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.s';

class _Sink implements UserTelemetrySink {
  final users = <String?>[];
  final properties = <String, String?>{};
  final topics = <String?>[];
  @override
  void setUser(String? id) => users.add(id);
  @override
  void setUserProperty(String name, String? value) => properties[name] = value;
  @override
  Future<void> setPlanTopic(String? plan) async => topics.add(plan);
}

void main() {
  test('reads the internal user id from the JWT, ignoring malformed tokens', () {
    expect(jwtSubject(_jwt({'sub': 'uuid-1', 'role': 'user'})), 'uuid-1');
    expect(jwtSubject('not-a-jwt'), isNull);
    expect(jwtSubject('a.!!!.c'), isNull);
    expect(jwtSubject(_jwt({'role': 'user'})), isNull);
  });

  test('maps the subscription to a closed plan value', () {
    SubscriptionInfo info(Map<String, dynamic> json) =>
        SubscriptionInfo.fromJson(json);
    expect(planOf(info({'isValid': true, 'isFreeTrial': true})), 'trial');
    expect(planOf(info({'isValid': true})), 'paid');
    expect(
      planOf(info({'isValid': false, 'dueDate': '2026-01-01T00:00:00Z'})),
      'expired',
    );
    expect(planOf(info({'isValid': false})), 'none');
    expect(userPlans, containsAll(['trial', 'paid', 'expired', 'none']));
  });

  UserTelemetrySync build(
    _Sink sink, {
    String? token,
    bool apiFails = false,
    Map<String, dynamic>? profile,
    Set<String> testers = const {},
  }) => UserTelemetrySync(
    readToken: () async => token,
    getSubscription: () async => apiFails
        ? throw StateError('offline')
        : SubscriptionInfo.fromJson({'isValid': true}),
    getOnboardingStatus: () async => apiFails
        ? throw StateError('offline')
        : OnboardingStatus.fromJson({
            'profile': profile ?? {'email': 'Team@x.com', 'phone': '5511'},
            'trainingPreferences': {'trainingFocus': 'superior'},
          }),
    internalTesterHashes: () async => testers,
    hashEmail: (email) => 'hash:${email.toLowerCase()}',
    sink: sink,
  );

  test('identifies the logged-in user and sets the segments', () async {
    final sink = _Sink();
    await build(
      sink,
      token: _jwt({'sub': 'uuid-1'}),
      testers: {'hash:team@x.com'},
    ).sync();
    expect(sink.users, ['uuid-1']);
    expect(sink.topics, ['paid']);
    expect(sink.properties, {
      'plan': 'paid',
      'has_whatsapp_link': 'true',
      'training_focus': 'superior',
      'internal_tester': 'true',
    });
  });

  test('never sends a free-form training focus', () async {
    final sink = _Sink();
    await UserTelemetrySync(
      readToken: () async => _jwt({'sub': 'uuid-1'}),
      getSubscription: () async => SubscriptionInfo.fromJson({}),
      getOnboardingStatus: () async => OnboardingStatus.fromJson({
        'profile': <String, dynamic>{},
        'trainingPreferences': {'trainingFocus': 'something else'},
      }),
      internalTesterHashes: () async => {},
      hashEmail: (e) => e,
      sink: sink,
    ).sync();
    expect(sink.properties['training_focus'], isNull);
    expect(sink.properties['has_whatsapp_link'], 'false');
    expect(sink.properties['internal_tester'], 'false');
  });

  test('clears identity, properties and topics on logout', () async {
    final sink = _Sink();
    await build(sink).sync();
    expect(sink.users, [null]);
    expect(sink.topics, [null]);
    expect(sink.properties.values, everyElement(isNull));
    expect(sink.properties.keys, contains('plan'));
  });

  test('keeps the user id when the profile cannot be loaded', () async {
    final sink = _Sink();
    await build(sink, token: _jwt({'sub': 'uuid-1'}), apiFails: true).sync();
    expect(sink.users, ['uuid-1']);
    expect(sink.properties, isEmpty);
    expect(sink.topics, isEmpty);
  });
}
