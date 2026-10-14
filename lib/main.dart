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

class _PersonaliaAppState extends ConsumerState<PersonaliaApp> {
  late final ValueNotifier<int> _billingAuth;
  final _startupCancelled = Completer<void>();
  bool _notificationsReady = false;

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
    if (token == null) {
      ref.invalidate(storeBillingProvider);
    } else {
      await ref.read(storeBillingProvider.notifier).initialize();
    }
  }

  @override
  void dispose() {
    _startupCancelled.complete();
    _billingAuth.removeListener(_syncStoreBilling);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
      routerConfig: router,
    );
  }
}
