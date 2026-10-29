import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/home/state/feature_access.dart';
import 'package:personalia_app/features/onboarding/data/onboarding_api.dart';

class _Onboarding extends OnboardingApi {
  _Onboarding(this.email) : super(Dio());
  final String? email;
  int calls = 0;
  @override
  Future<OnboardingStatus> getStatus() async {
    calls++;
    return OnboardingStatus(
      profile: OnboardingProfile(email: email),
      disclaimerAccepted: true,
      anamnesis: null,
      trainingPreferences: null,
      nextStep: 'DONE',
      completed: true,
    );
  }
}

void main() {
  const demo = 'Review@Example.com';

  Future<bool> access({
    required bool subscribed,
    required Set<String> hashes,
    String? email = demo,
    _Onboarding? onboarding,
  }) async {
    final container = ProviderContainer(
      overrides: [
        subscriptionProvider.overrideWith(
          (ref) async =>
              SubscriptionInfo(isValid: subscribed, isFreeTrial: false),
        ),
        unlimitedAccessHashesProvider.overrideWith((ref) async => hashes),
        onboardingApiProvider.overrideWithValue(
          onboarding ?? _Onboarding(email),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(featureAccessProvider, (_, _) {});
    await container.read(subscriptionProvider.future);
    await container.read(unlimitedAccessProvider.future);
    return sub.read();
  }

  test('hashes the normalized email', () {
    expect(hashEmail('  Review@Example.com '), hashEmail('review@example.com'));
    expect(hashEmail('a@b.c'), hasLength(64));
  });

  test('parses hashes separated by commas, spaces or lines', () {
    expect(parseEmailHashes(' AA, bb\ncc  '), {'aa', 'bb', 'cc'});
    expect(parseEmailHashes(''), isEmpty);
  });

  test('subscribers have access', () async {
    expect(await access(subscribed: true, hashes: {}), true);
  });

  test('listed email has access without a subscription', () async {
    expect(
      await access(
        subscribed: false,
        hashes: {hashEmail('review@example.com')},
      ),
      true,
    );
  });

  test('unlisted email stays locked without a subscription', () async {
    expect(
      await access(subscribed: false, hashes: {hashEmail('other@example.com')}),
      false,
    );
  });

  test('does not fetch the profile when no email is listed', () async {
    final onboarding = _Onboarding(demo);
    expect(
      await access(subscribed: false, hashes: {}, onboarding: onboarding),
      false,
    );
    expect(onboarding.calls, 0);
  });
}
