import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/account/presentation/edit_profile_screen.dart';
import '../../features/assistant/presentation/assistant_chat_screen.dart';
import '../../features/account/presentation/edit_training_preferences_screen.dart';
import '../../features/auth/presentation/app_access_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_login_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/coming_soon/presentation/coming_soon_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/onboarding/data/onboarding_api.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/referral/presentation/referral_screen.dart';
import '../../features/reports/presentation/body_report_screen.dart';
import '../../features/reports/presentation/frequency_report_screen.dart';
import '../../features/reports/presentation/load_evolution_report_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/volume_report_screen.dart';
import '../../features/home/data/app_api.dart';
import '../../features/workout/presentation/current_workout_screen.dart';
import '../../features/workout/presentation/last_workout_screen.dart';
import '../../features/workout/presentation/rest_timer_screen.dart';
import '../../features/workout/presentation/today_workout_screen.dart';
import '../../features/workout/presentation/workout_day_detail_screen.dart';
import '../network/token_storage.dart';
import '../widgets/app_shell.dart';

GoRouter buildRouter({
  required TokenStorage tokenStorage,
  required ValueNotifier<int> refresh,
  required OnboardingApi onboardingApi,
}) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) async {
      String? token;
      try {
        token = await tokenStorage.read();
      } catch (_) {
        token = null;
      }
      final loggedIn = token != null;
      final loggingIn = state.matchedLocation.startsWith('/login');
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (!loggedIn) return loggingIn ? null : '/login';

      // Falha transitória de rede na checagem de onboarding não deve travar o usuário fora
      // do app — fail-open (assume completo) e deixa a wizard ser reaberta manualmente se
      // necessário. Mas um 404 aqui é diferente: o backend não reconhece esse usuário (token
      // órfão, ex.: base local resetada em dev) — nesse caso força a wizard em vez de deixar
      // a Home quebrada tentando carregar dados de um usuário inexistente.
      var onboardingComplete = true;
      try {
        onboardingComplete = (await onboardingApi.getStatus()).completed;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          onboardingComplete = false;
        }
      } catch (_) {}

      if (!onboardingComplete && !onOnboarding) return '/onboarding';
      if (onboardingComplete && onOnboarding) return '/home';
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login/phone', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/login/password', builder: (context, state) => const PasswordLoginScreen()),
      // Reset só por email: apenas contas criadas direto no app (Fase 2). Conta do WhatsApp usa /login/access.
      GoRoute(path: '/login/password/forgot', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/login/access', builder: (context, state) => const AppAccessScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(currentLocation: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/referral', builder: (context, state) => const ReferralScreen()),
          GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
        ],
      ),
      // Histórico saiu do rodapé (virou item do Menu): tela cheia com voltar.
      GoRoute(path: '/workout/last', builder: (context, state) => const LastWorkoutScreen()),
      // Chat de dúvidas (botão flutuante). ?machine=1 = atalho "Pesquisar máquina" (abre a câmera).
      GoRoute(
        path: '/assistant',
        builder: (context, state) => AssistantChatScreen(openCameraOnStart: state.uri.queryParameters['machine'] == '1'),
      ),
      GoRoute(path: '/reports/load-evolution', builder: (context, state) => const LoadEvolutionReportScreen()),
      GoRoute(path: '/reports/body', builder: (context, state) => const BodyReportScreen()),
      GoRoute(path: '/reports/volume', builder: (context, state) => const VolumeReportScreen()),
      GoRoute(path: '/reports/frequency', builder: (context, state) => const FrequencyReportScreen()),
      GoRoute(path: '/account/profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/account/preferences', builder: (context, state) => const EditTrainingPreferencesScreen()),
      GoRoute(path: '/workout/current', builder: (context, state) => const CurrentWorkoutScreen()),
      GoRoute(path: '/workout/today', builder: (context, state) => const TodayWorkoutScreen()),
      GoRoute(
        path: '/workout/day',
        builder: (context, state) => WorkoutDayDetailScreen(day: state.extra as WorkoutDay),
      ),
      GoRoute(
        path: '/workout/rest-timer',
        builder: (context, state) => RestTimerScreen(args: state.extra as RestTimerArgs),
      ),
      GoRoute(
        path: '/coming-soon/:section',
        builder: (context, state) => ComingSoonScreen(title: _sectionTitle(state.pathParameters['section'])),
      ),
    ],
  );
}

String _sectionTitle(String? section) {
  switch (section) {
    case 'perfil':
      return 'Atualizar Perfil';
    case 'preferencias':
      return 'Preferências de Treino';
    case 'trocar-exercicio':
      return 'Trocar Exercício';
    case 'relatorios':
      return 'Relatórios de Desempenho';
    default:
      return 'Em breve';
  }
}
