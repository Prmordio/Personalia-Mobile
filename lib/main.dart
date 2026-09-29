import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/notifications/rest_alarm.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/data/onboarding_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Aviso de fim do descanso (notificação local). Falha aqui não impede o app de abrir.
  await LocalNotificationRestAlarm.instance.init();
  runApp(const ProviderScope(child: PersonaliaApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  return buildRouter(
    tokenStorage: ref.watch(tokenStorageProvider),
    refresh: ref.watch(authRefreshProvider),
    onboardingApi: ref.watch(onboardingApiProvider),
  );
});

class PersonaliaApp extends ConsumerWidget {
  const PersonaliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'PersonalIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
