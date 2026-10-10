import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Telemetry stays inactive until Firebase initialization, including in tests.
class AppTelemetry {
  AppTelemetry._();
  static final instance = AppTelemetry._();
  bool _enabled = false;
  bool get enabled => _enabled;
  String? _lastScreen;

  Future<void> initialize() async {
    _enabled = const bool.fromEnvironment(
      'TELEMETRY_ENABLED',
      defaultValue: kReleaseMode,
    );
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(_enabled);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      _enabled,
    );
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(_enabled);
    if (!_enabled) return;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        _ignoreFailure(
          () => FirebaseCrashlytics.instance.recordError(
            details.exception.runtimeType.toString(),
            details.stack,
            fatal: true,
            reason: 'flutter_framework',
          ),
        ),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        _ignoreFailure(
          () => FirebaseCrashlytics.instance.recordError(
            error.runtimeType.toString(),
            stack,
            fatal: true,
            reason: 'unhandled_async',
          ),
        ),
      );
      return true;
    };
  }

  void event(String name) {
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(() => FirebaseAnalytics.instance.logEvent(name: name)),
    );
  }

  void screen(String path) {
    if (!_enabled) return;
    final name = screenName(path);
    if (name == _lastScreen) return;
    _lastScreen = name;
    unawaited(
      _ignoreFailure(
        () => FirebaseAnalytics.instance.logScreenView(screenName: name),
      ),
    );
  }

  /// Do not transmit query strings, dynamic identifiers or unknown paths.
  static String screenName(String location) {
    final path = Uri.parse(location).path;
    const routes = {
      '/login',
      '/login/phone',
      '/login/password',
      '/login/password/forgot',
      '/login/access',
      '/onboarding',
      '/home',
      '/reports',
      '/referral',
      '/menu',
      '/assistant',
      '/reports/load-evolution',
      '/reports/body',
      '/reports/volume',
      '/reports/frequency',
      '/account/profile',
      '/account/preferences',
      '/workout/last',
      '/workout/current',
      '/workout/today',
      '/workout/day',
      '/workout/rest-timer',
      '/workout/swap-exercise',
    };
    if (routes.contains(path)) return path;
    if (path.startsWith('/coming-soon/')) return '/coming-soon';
    return 'other';
  }

  /// Only a category is reported: network errors may contain tokens or bodies.
  void recoverableError(Object error, StackTrace stack, String operation) {
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(
        () => FirebaseCrashlytics.instance.recordError(
          error.runtimeType.toString(),
          stack,
          reason: operation,
        ),
      ),
    );
  }

  Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Observability must not interrupt a successful user operation.
    }
  }
}
