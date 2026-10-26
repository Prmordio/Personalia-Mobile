import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/onboarding/data/onboarding_api.dart';
import 'package:personalia_app/features/onboarding/presentation/anamnesis_steps.dart';
import 'package:personalia_app/features/onboarding/state/onboarding_controller.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'leaving the health step without opening the text fields does not throw',
    (tester) async {
      final controller = OnboardingController(OnboardingApi(Dio()), AppApi(Dio()));
      // "Não" nas duas perguntas: os campos de texto nunca chegam a ser exibidos.
      controller.state = const OnboardingState(
        resumed: true,
        hasDiseases: false,
        hasPhysicalLimitations: false,
        step: OnboardingStep.healthConditions,
      );
      final container = ProviderContainer(
        overrides: [onboardingControllerProvider.overrideWith((ref) => controller)],
      );
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: HealthConditionsStep(),
            ),
          ),
        );
        expect(find.byType(TextField), findsNothing);

        // Sair da tela (ex.: Continuar → nível de atividade) descarta o State.
        await tester.pumpWidget(const SizedBox.shrink());

        expect(tester.takeException(), isNull);
      } finally {
        container.dispose();
      }
    },
  );
}
