import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Custom Performance trace. Stopping more than once is ignored, so callers can stop
/// it from several exit paths (success, error, dispose) without bookkeeping.
abstract interface class TelemetryTrace {
  void stop({
    Map<String, String> attributes = const {},
    Map<String, int> metrics = const {},
  });
}

class _NoopTrace implements TelemetryTrace {
  const _NoopTrace();
  @override
  void stop({
    Map<String, String> attributes = const {},
    Map<String, int> metrics = const {},
  }) {}
}

class _FirebaseTrace implements TelemetryTrace {
  _FirebaseTrace(String name) {
    _trace = Future(() async {
      final trace = FirebasePerformance.instance.newTrace(name);
      await trace.start();
      return trace;
    });
  }
  late final Future<Trace> _trace;
  bool _stopped = false;

  @override
  void stop({
    Map<String, String> attributes = const {},
    Map<String, int> metrics = const {},
  }) {
    if (_stopped) return;
    _stopped = true;
    unawaited(
      AppTelemetry._ignoreFailure(() async {
        final trace = await _trace;
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
        for (final entry in metrics.entries) {
          trace.setMetric(entry.key, entry.value);
        }
        await trace.stop();
      }),
    );
  }
}

/// Single entry point for Analytics, Crashlytics and Performance. Features never
/// import the Firebase SDKs: telemetry stays inactive until Firebase initialization,
/// including in tests, and every failure is swallowed.
class AppTelemetry {
  AppTelemetry._();
  static final instance = AppTelemetry._();
  bool _enabled = false;
  bool get enabled => _enabled;
  String? _lastScreen;
  String? _pendingScreen;
  final _sinceLaunch = Stopwatch();
  int? _firstScreenMs;
  String? _firstScreen;
  bool _startupReported = false;
  bool _inAppSuppressed = false;

  /// Nenhuma campanha do In-App Messaging aparece durante um treino em andamento.
  void suppressInAppMessages(bool suppressed) {
    _inAppSuppressed = suppressed;
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(
        () => FirebaseInAppMessaging.instance.setMessagesSuppressed(suppressed),
      ),
    );
  }

  /// Called first thing in `main()`: startup time is measured from here.
  void markLaunch() {
    if (!_sinceLaunch.isRunning) _sinceLaunch.start();
  }

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
    // In-App Messaging: campanhas do console disparadas por eventos do Analytics.
    await _ignoreFailure(() async {
      final messaging = FirebaseInAppMessaging.instance;
      await messaging.setAutomaticDataCollectionEnabled(_enabled);
      await messaging.setMessagesSuppressed(!_enabled || _inAppSuppressed);
    });
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
    // The first route is shown before Firebase is ready; report it now.
    final pending = _pendingScreen;
    _pendingScreen = null;
    if (pending != null) screen(pending);
    _reportStartup();
  }

  /// Analytics event. Parameters must be closed enums, booleans or numbers: never
  /// user text, identifiers or health data (see [sanitizeParams]).
  void event(String name, [Map<String, Object?> params = const {}]) {
    if (!_enabled) return;
    final clean = sanitizeParams(params);
    unawaited(
      _ignoreFailure(
        () => FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: clean.isEmpty ? null : clean,
        ),
      ),
    );
  }

  /// Analytics only accepts strings and numbers; booleans become `'true'`/`'false'`,
  /// nulls are dropped and strings are capped at the 100-character limit.
  static Map<String, Object> sanitizeParams(Map<String, Object?> params) {
    final clean = <String, Object>{};
    for (final MapEntry(:key, :value) in params.entries) {
      if (clean.length == 25) break;
      switch (value) {
        case null:
          continue;
        case bool b:
          clean[key] = b.toString();
        case num n:
          clean[key] = n;
        default:
          final text = value.toString();
          clean[key] = text.length > 100 ? text.substring(0, 100) : text;
      }
    }
    return clean;
  }

  void screen(String path) {
    final name = screenName(path);
    if (_firstScreenMs == null) {
      _firstScreenMs = _sinceLaunch.elapsedMilliseconds;
      _firstScreen = name;
    }
    if (!_enabled) {
      _pendingScreen = path;
      return;
    }
    if (name == _lastScreen) return;
    _lastScreen = name;
    setKey('screen', name);
    breadcrumb('nav:$name');
    unawaited(
      _ignoreFailure(
        () => FirebaseAnalytics.instance.logScreenView(screenName: name),
      ),
    );
    _reportStartup();
  }

  /// `app_start`: time from `main()` until the first route was on screen. The trace's
  /// own duration is meaningless (Firebase starts later); read the metric.
  void _reportStartup() {
    final ms = _firstScreenMs;
    if (_startupReported || !_enabled || ms == null || !_sinceLaunch.isRunning) {
      return;
    }
    _startupReported = true;
    startTrace('app_start').stop(
      attributes: {'landing': _firstScreen ?? 'other'},
      metrics: {'ms_to_first_screen': ms},
    );
  }

  /// Do not transmit query strings, dynamic identifiers or unknown paths.
  static String screenName(String location) {
    final path = Uri.parse(location).path;
    const routes = {
      '/login',
      '/login/phone',
      '/login/register',
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
      '/workout/execution-analysis',
    };
    if (routes.contains(path)) return path;
    return 'other';
  }

  /// Pseudonymous internal user id (JWT `sub`), never phone/email/CPF. `null` on logout.
  /// Lets support find one customer's crashes and joins app events to the backend.
  void setUser(String? id) {
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(() async {
        await FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
        await FirebaseAnalytics.instance.setUserId(id: id);
      }),
    );
  }

  /// Analytics user property (max 25 per project, low cardinality), mirrored as a
  /// Crashlytics key so crashes can be split the same way.
  void setUserProperty(String name, String? value) {
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(
        () => FirebaseAnalytics.instance.setUserProperty(
          name: name,
          value: value,
        ),
      ),
    );
    setKey(name, value ?? '');
  }

  /// Crashlytics custom key: attached to every subsequent crash report.
  void setKey(String key, Object value) {
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(
        () => FirebaseCrashlytics.instance.setCustomKey(key, value),
      ),
    );
  }

  /// Crashlytics log line shown before a crash. No payloads, tokens or user text.
  void breadcrumb(String message) {
    if (!_enabled) return;
    unawaited(_ignoreFailure(() => FirebaseCrashlytics.instance.log(message)));
  }

  TelemetryTrace startTrace(String name) {
    if (!_enabled) return const _NoopTrace();
    try {
      return _FirebaseTrace(name);
    } catch (_) {
      return const _NoopTrace();
    }
  }

  /// Only a category is reported: network errors may contain tokens or bodies.
  /// [operation] must be a stable category (it is how issues are filtered); variable
  /// text such as a store message goes in [detail], sent as a custom key.
  void recoverableError(
    Object error,
    StackTrace stack,
    String operation, {
    String? detail,
  }) {
    if (!_enabled) return;
    unawaited(
      _ignoreFailure(() async {
        await FirebaseCrashlytics.instance.setCustomKey(
          'error_detail',
          detail ?? '',
        );
        await FirebaseCrashlytics.instance.recordError(
          error.runtimeType.toString(),
          stack,
          reason: operation,
        );
      }),
    );
  }

  static Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Observability must not interrupt a successful user operation.
    }
  }
}
