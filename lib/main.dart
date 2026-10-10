import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/rest_alarm.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/telemetry/app_telemetry.dart';
import 'features/onboarding/data/onboarding_api.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppTelemetry.instance.initialize();
  await LocalNotificationRestAlarm.instance.init();
  await FcmService.instance.init();
  runApp(const ProviderScope(child: PersonaliaApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(
    tokenStorage: ref.watch(tokenStorageProvider),
    refresh: ref.watch(authRefreshProvider),
    onboardingApi: ref.watch(onboardingApiProvider),
  );
  void trackScreen() => AppTelemetry.instance.screen(router.routerDelegate.currentConfiguration.uri.path);
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(_routerProvider);

      // Habilita navegação via push notification a partir daqui
      FcmService.instance.onRoute = router.go;

      // Notificação tocada com app encerrado: navega para rota capturada no init
      final pending = FcmService.instance.pendingRoute;
      if (pending != null) {
        FcmService.instance.clearPendingRoute();
        router.go(pending);
      }
    });

    // Registra (ou re-registra) o FCM token a cada mudança de estado de auth (login/logout)
    ref.listenManual(authRefreshProvider, (prev, next) {
      final api = ref.read(deviceTokenApiProvider);
      FcmService.instance.registerToken(api.register);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'PersonalIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
