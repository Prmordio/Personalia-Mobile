import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/data/app_api.dart';
import '../../features/home/state/feature_access.dart';
import '../../features/onboarding/data/onboarding_api.dart';
import '../notifications/fcm_service.dart';
import '../providers.dart';
import '../remote_config/app_remote_config.dart';
import 'app_telemetry.dart';

/// `sub` claim of the JWT (internal user UUID). The signature is not checked: the
/// value is only a telemetry label, never an authorization decision.
String? jwtSubject(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final sub = payload is Map ? payload['sub'] : null;
    return sub is String && sub.isNotEmpty ? sub : null;
  } catch (_) {
    return null;
  }
}

/// Closed set used for the `plan` user property and the `plan_<x>` FCM topic.
const userPlans = {'trial', 'paid', 'expired', 'none'};

String planOf(SubscriptionInfo info) {
  if (info.isValid) return info.isFreeTrial ? 'trial' : 'paid';
  return info.dueDate != null || info.status != null ? 'expired' : 'none';
}

const _trainingFocuses = {'superior', 'inferior', 'corpo_todo'};

/// Where the user identity and segments go (Analytics/Crashlytics + FCM topics).
abstract interface class UserTelemetrySink {
  void setUser(String? id);
  void setUserProperty(String name, String? value);
  Future<void> setPlanTopic(String? plan);
}

/// Keeps the telemetry identity in sync with the logged-in account. Runs on app start,
/// login/logout and after a purchase. Network failures only skip the properties.
class UserTelemetrySync {
  UserTelemetrySync({
    required this._readToken,
    required this._getSubscription,
    required this._getOnboardingStatus,
    required this._internalTesterHashes,
    required this._hashEmail,
    required this._sink,
  });

  final Future<String?> Function() _readToken;
  final Future<SubscriptionInfo> Function() _getSubscription;
  final Future<OnboardingStatus> Function() _getOnboardingStatus;
  final Future<Set<String>> Function() _internalTesterHashes;
  final String Function(String email) _hashEmail;
  final UserTelemetrySink _sink;

  Future<void> sync() async {
    String? token;
    try {
      token = await _readToken();
    } catch (_) {}
    final userId = token == null ? null : jwtSubject(token);
    _sink.setUser(userId);
    if (userId == null) {
      for (final name in const [
        'plan',
        'has_whatsapp_link',
        'training_focus',
        'internal_tester',
      ]) {
        _sink.setUserProperty(name, null);
      }
      await _sink.setPlanTopic(null);
      return;
    }
    await Future.wait([_syncPlan(), _syncProfile()]);
  }

  Future<void> _syncPlan() async {
    try {
      final plan = planOf(await _getSubscription());
      _sink.setUserProperty('plan', plan);
      await _sink.setPlanTopic(plan);
    } catch (_) {}
  }

  Future<void> _syncProfile() async {
    try {
      final status = await _getOnboardingStatus();
      final phone = status.profile.phone;
      _sink.setUserProperty(
        'has_whatsapp_link',
        (phone != null && phone.isNotEmpty).toString(),
      );
      final focus = status.trainingPreferences?.trainingFocus;
      _sink.setUserProperty(
        'training_focus',
        _trainingFocuses.contains(focus) ? focus : null,
      );
      final email = status.profile.email;
      final testers = await _internalTesterHashes().catchError(
        (_) => <String>{},
      );
      _sink.setUserProperty(
        'internal_tester',
        (email != null &&
                email.isNotEmpty &&
                testers.contains(_hashEmail(email)))
            .toString(),
      );
    } catch (_) {}
  }
}

/// Production sink: Analytics/Crashlytics via [AppTelemetry], topics via FCM.
class FirebaseUserTelemetrySink implements UserTelemetrySink {
  FirebaseUserTelemetrySink(this._setPlanTopic);
  final Future<void> Function(String? plan) _setPlanTopic;

  @override
  void setUser(String? id) => AppTelemetry.instance.setUser(id);

  @override
  void setUserProperty(String name, String? value) =>
      AppTelemetry.instance.setUserProperty(name, value);

  @override
  Future<void> setPlanTopic(String? plan) => _setPlanTopic(plan);
}

final userTelemetrySyncProvider = Provider<UserTelemetrySync>((ref) {
  final appApi = ref.watch(appApiProvider);
  final onboardingApi = ref.watch(onboardingApiProvider);
  return UserTelemetrySync(
    readToken: ref.watch(tokenStorageProvider).read,
    getSubscription: appApi.getSubscription,
    getOnboardingStatus: onboardingApi.getStatus,
    internalTesterHashes: () async => parseEmailHashes(
      (await ref.read(remoteConfigProvider.future)).getString(
        RemoteConfigKeys.internalTesterEmailHashes,
      ),
    ),
    hashEmail: hashEmail,
    sink: FirebaseUserTelemetrySink(FcmService.instance.setPlanTopic),
  );
});
