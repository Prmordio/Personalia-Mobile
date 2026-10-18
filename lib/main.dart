import 'features/workout/state/workout_session_cache.dart';
import 'features/workout/state/completed_workout_session.dart';
import 'features/home/state/today_workout_override.dart';
import 'features/home/data/app_api.dart';
import 'features/workout/state/workout_live_labels.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/l10n/l10n.dart';
import 'core/locale/locale_controller.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/rest_alarm.dart';
import 'core/providers.dart';
import 'core/startup_task.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/billing/store_billing_controller.dart';
import 'core/telemetry/app_telemetry.dart';
import 'features/onboarding/data/onboarding_api.dart';
import 'firebase_options.dart';
import 'features/workout/state/workout_live_activity.dart';
import 'features/workout/state/active_workout_session.dart';
import 'features/workout/presentation/rest_timer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PersonaliaApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(
    tokenStorage: ref.watch(tokenStorageProvider),
    refresh: ref.watch(authRefreshProvider),
    onboardingApi: ref.watch(onboardingApiProvider),
  );
  void trackScreen() => AppTelemetry.instance.screen(
    router.routerDelegate.currentConfiguration.uri.path,
  );
  router.routerDelegate.addListener(trackScreen);
  ref.onDispose(() {
    router.routerDelegate.removeListener(trackScreen);
    router.dispose();
  });
  return router;
});

class PersonaliaApp extends ConsumerStatefulWidget {
  const PersonaliaApp({super.key});

  @override
  ConsumerState<PersonaliaApp> createState() => _PersonaliaAppState();
}

class _PersonaliaAppState extends ConsumerState<PersonaliaApp>
    with WidgetsBindingObserver {
  late final ValueNotifier<int> _billingAuth;
  final _startupCancelled = Completer<void>();
  bool _notificationsReady = false;
  Timer? _workoutSyncTimer;
  String? _restoredWorkoutOwner;

  void _clearWorkoutAccountState() {
    ref.invalidate(todayWorkoutProvider);
    ref.invalidate(currentWorkoutProvider);
    ref.invalidate(lastWorkoutProvider);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(effectiveTodayWorkoutProvider);
    ref.read(todayDayOverrideProvider.notifier).state = null;
    ref.invalidate(restTimerProvider);
    ref.read(activeWorkoutSessionProvider.notifier).state = null;
    ref.read(completedWorkoutSessionProvider.notifier).state = null;
  }

  Future<void> _restoreWorkoutCache() async {
    try {
      final cache = ref.read(workoutSessionCacheProvider);
      await cache.bind();
      final changed = cache.owner != _restoredWorkoutOwner;
      _restoredWorkoutOwner = cache.owner;
      if (!mounted) return;
      if (changed) {
        _clearWorkoutAccountState();
        if (cache.startedAt != null && cache.active != null) {
          final day = cache.active!['day'] as String;
          ref.read(activeWorkoutSessionProvider.notifier).state =
              ActiveWorkoutSession(dayName: day, startedAt: cache.startedAt!);
          ref.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(
            dayName: day,
            date: DateTime.now(),
          );
        }
        final complete = cache.lastCompletion;
        if (complete != null) {
          final ended = DateTime.parse(complete['endedAt'] as String);
          final started = DateTime.parse(complete['startedAt'] as String);
          ref
              .read(completedWorkoutSessionProvider.notifier)
              .state = CompletedWorkoutSession(
            dayName: complete['dayName'] as String,
            completedAt: ended,
            duration: ended.difference(started),
            completedCount: (complete['exercises'] as List).length,
            totalCount:
                (complete['totalCount'] as num?)?.toInt() ??
                (complete['exercises'] as List).length,
          );
        }
      }
      if (cache.pendingCount > 0) {
        unawaited(
          cache
              .sync(ref.read(appApiProvider).syncCachedWorkout)
              .then((_) {
                if (mounted) {
                  ref.invalidate(lastWorkoutProvider);
                  ref.invalidate(workoutHistoryProvider);
                }
              })
              .catchError((Object error) {
                debugPrint('Workout pending upload: $error');
              }),
        );
      }
    } catch (error) {
      if (mounted &&
          ref.read(workoutSessionCacheProvider).owner !=
              _restoredWorkoutOwner) {
        _restoredWorkoutOwner = ref.read(workoutSessionCacheProvider).owner;
        _clearWorkoutAccountState();
      }
      debugPrint('Workout recovery/sync: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_restoreWorkoutCache());
  }

  Future<void> _initializeServices() async {
    final alarm = runStartupTask(
      'rest_alarm',
      LocalNotificationRestAlarm.instance.init,
      cancelled: _startupCancelled.future,
    );
    final firebaseReady = await runStartupTask('firebase', () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }, cancelled: _startupCancelled.future);
    if (!firebaseReady || !mounted) {
      await alarm;
      return;
    }
    await Future.wait([
      runStartupTask(
        'telemetry',
        AppTelemetry.instance.initialize,
        cancelled: _startupCancelled.future,
      ),
      runStartupTask(
        'notifications',
        _initializeNotifications,
        cancelled: _startupCancelled.future,
      ),
    ]);
    await alarm;
  }

  Future<void> _initializeNotifications() async {
    await FcmService.instance.init();
    if (!mounted) return;
    _notificationsReady = true;
    final pending = FcmService.instance.pendingRoute;
    if (pending != null) {
      FcmService.instance.clearPendingRoute();
      ref.read(_routerProvider).go(pending);
    }
    unawaited(
      FcmService.instance.registerToken(
        ref.read(deviceTokenApiProvider).register,
      ),
    );
  }

  Future<void> _syncStoreBilling() async {
    final token = await ref
        .read(tokenStorageProvider)
        .read()
        .catchError((_) => null);
    if (!mounted) return;
    if (token == null) await ref.read(workoutLiveProvider.notifier).end();
    await _restoreWorkoutCache();
    if (!mounted) return;
    if (token == null) {
      ref.invalidate(storeBillingProvider);
    } else {
      await ref.read(storeBillingProvider.notifier).initialize();
    }
  }

  @override
  void dispose() {
    _startupCancelled.complete();
    _workoutSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _billingAuth.removeListener(_syncStoreBilling);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workoutSyncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_restoreWorkoutCache());
      }
    });
    _billingAuth = ref.read(authRefreshProvider);
    _billingAuth.addListener(_syncStoreBilling);
    _syncStoreBilling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(_routerProvider);

      // Habilita navegação via push notification a partir daqui
      FcmService.instance.onRoute = router.go;
      unawaited(_initializeServices());
    });

    // Registra (ou re-registra) o FCM token a cada mudança de estado de auth (login/logout)
    ref.listenManual(authRefreshProvider, (prev, next) {
      if (_notificationsReady) {
        final api = ref.read(deviceTokenApiProvider);
        unawaited(FcmService.instance.registerToken(api.register));
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ActiveWorkoutSession?>(activeWorkoutSessionProvider, (
      _,
      session,
    ) {
      if (session != null) {
        ref
            .read(workoutSessionCacheProvider)
            .start(session.dayName, session.startedAt);
      }
    });
    ref.listen<WorkoutLiveState?>(workoutLiveProvider, (previous, next) {
      if (next == null) return;
      final cache = ref.read(workoutSessionCacheProvider);
      cache.mergeNative(next.data);
      if (cache.active == null || cache.active!['day'] != next.data['day']) {
        return;
      }
      for (var i = 0; i < next.exercises.length; i++) {
        final e = next.exercises[i] as Map;
        if (cache.ignoresNative(e['name'] as String)) continue;
        if (previous == null && next.data['weights']?[e['name']] is String) {
          ref
              .read(
                restTimerProvider((
                  e['name'] as String,
                  (e['restSeconds'] as num).toInt(),
                  (e['sets'] as num).toInt(),
                )).notifier,
              )
              .setWeight(
                cache.record((
                          e['name'] as String,
                          (e['restSeconds'] as num).toInt(),
                          (e['sets'] as num).toInt(),
                        ))?['weight']
                        as String? ??
                    next.data['weights'][e['name']] as String,
              );
        }
        ref
            .read(
              restTimerProvider((
                e['name'] as String,
                (e['restSeconds'] as num).toInt(),
                (e['sets'] as num).toInt(),
              )).notifier,
            )
            .syncExecution(
              (next.data['completed'][i] as num).toInt(),
              finished: next.exerciseFinished(i),
            );
      }
      final session = ref.read(activeWorkoutSessionProvider);
      final restored = next.restoreSession(session);
      if (!identical(restored, session)) {
        ref.read(activeWorkoutSessionProvider.notifier).state = restored;
      }
    });
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'PersonalIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final labels = workoutLiveLabels(AppLocalizations.of(context));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(ref.read(workoutLiveProvider.notifier).localize(labels));
          }
        });
        return child ?? const SizedBox.shrink();
      },
      routerConfig: router,
    );
  }
}
