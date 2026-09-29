import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/onboarding_controller.dart';
import 'anamnesis_steps.dart';
import 'create_password_step.dart';
import 'disclaimer_cpf_steps.dart';
import 'free_trial_step.dart';
import 'generating_workout_screen.dart';
import 'profile_steps.dart';
import 'training_preferences_steps.dart';

/// Wizard de cadastro do app mobile — espelha o funil de conversa do WhatsApp (perfil →
/// disclaimer/CPF → anamnese → preferências de treino) numa sequência de telas nativas.
/// Ao entrar, consulta GET /app/onboarding (via OnboardingController.resume) pra retomar do
/// passo certo, cobrindo o caso do usuário fechar o app no meio do cadastro.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    if (!state.resumed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (state.step) {
      case OnboardingStep.name:
        return const NameStep();
      case OnboardingStep.cpf:
        return const CpfStep();
      case OnboardingStep.disclaimer:
        return const DisclaimerStep();
      case OnboardingStep.gender:
        return const GenderStep();
      case OnboardingStep.birthDate:
        return const BirthDateStep();
      case OnboardingStep.weight:
        return const WeightStep();
      case OnboardingStep.height:
        return const HeightStep();
      case OnboardingStep.email:
        return const EmailStep();
      case OnboardingStep.password:
        return const CreatePasswordStep();
      case OnboardingStep.profileConfirmation:
        return const ProfileConfirmationStep();
      case OnboardingStep.mainGoal:
        return const MainGoalStep();
      case OnboardingStep.healthConditions:
        return const HealthConditionsStep();
      case OnboardingStep.activityLevel:
        return const ActivityLevelStep();
      case OnboardingStep.anamnesisConfirmation:
        return const AnamnesisConfirmationStep();
      case OnboardingStep.trainingDuration:
        return const DurationRangeStep();
      case OnboardingStep.trainingDays:
        return const TrainingDaysStep();
      case OnboardingStep.gymTime:
        return const GymTimeStep();
      case OnboardingStep.cardio:
        return const CardioStep();
      case OnboardingStep.trainingFocus:
        return const TrainingFocusStep();
      case OnboardingStep.freeTrial:
        return const FreeTrialStep();
      case OnboardingStep.generating:
      case OnboardingStep.done:
        return const GeneratingWorkoutScreen();
    }
  }
}
