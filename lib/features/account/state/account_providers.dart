import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/data/onboarding_api.dart';

/// Perfil + preferências atuais (mesmo GET do onboarding) — preenche as telas de edição do Menu.
final accountStatusProvider = FutureProvider.autoDispose<OnboardingStatus>((ref) {
  return ref.watch(onboardingApiProvider).getStatus();
});
