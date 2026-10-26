import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/onboarding/data/onboarding_api.dart';
import 'package:personalia_app/features/onboarding/presentation/profile_form_step.dart';
import 'package:personalia_app/features/onboarding/state/onboarding_controller.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

class _Api extends OnboardingApi {
  _Api() : super(Dio());
  final calls = <String>[];
  bool? accepted;
  String? cpf;
  bool rejectCpf = false;
  @override
  Future<void> updateProfile({
    required String name,
    required String gender,
    required String birthDate,
    required num weight,
    required num height,
    required String email,
    String? cpf,
  }) async {
    calls.add('profile');
  }

  @override
  Future<void> acceptDisclaimer({
    required bool accepted,
    required String cpf,
  }) async {
    calls.add('terms');
    this.accepted = accepted;
    this.cpf = cpf;
    if (rejectCpf) throw OnboardingValidationException({'cpf': 'Invalid CPF'});
  }
}

void main() {
  test(
    'profile submission requires CPF and explicit acceptance before any HTTP call',
    () async {
      final api = _Api();
      final controller = OnboardingController(api, AppApi(Dio()));
      try {
        Future<bool> submit(String cpf, bool accepted) =>
            controller.submitProfileForm(
              name: 'Test User',
              cpf: cpf,
              gender: 'Masculino',
              birthDate: DateTime(1990, 3, 15),
              weight: 80,
              height: 180,
              email: 'test@example.com',
              accepted: accepted,
            );
        expect(await submit('', true), isFalse);
        expect(controller.state.fieldErrors, contains('cpf'));
        for (final invalid in [
          '00000000000',
          '11111111111',
          '52998224724',
          '52998224715',
        ]) {
          expect(await submit(invalid, true), isFalse);
          expect(controller.state.fieldErrors, contains('cpf'));
        }
        expect(await submit('52998224725', false), isFalse);
        expect(api.calls, isEmpty);
        expect(await submit('52998224725', true), isTrue);
        expect(api.calls, ['profile', 'terms']);
        expect(api.accepted, isTrue);
        expect(api.cpf, '52998224725');
        expect(controller.state.step, OnboardingStep.mainGoal);
      } finally {
        controller.dispose();
      }
    },
  );

  for (final language in ['pt', 'en', 'es']) {
    testWidgets(
      'direct form keeps mandatory CPF and unchecked terms ($language)',
      (tester) async {
        final api = _Api();
        final controller = OnboardingController(api, AppApi(Dio()));
        controller.state = const OnboardingState(
          name: 'Test User',
          gender: 'Masculino',
          cpf: '',
          weight: 80,
          height: 180,
          email: 'test@example.com',
          resumed: true,
        ).copyWith(birthDate: DateTime(1990, 3, 15));
        final container = ProviderContainer(
          overrides: [
            onboardingControllerProvider.overrideWith((ref) => controller),
          ],
        );
        final l = lookupAppLocalizations(Locale(language));
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const ProfileFormStep(),
              ),
            ),
          );
          expect(find.text(l.onboardingProfileFormTitle), findsOneWidget);
          expect(find.text(l.pular), findsNothing);
          final button = find.widgetWithText(ElevatedButton, l.continuar);
          expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
          final checkbox = find.byType(CheckboxListTile);
          await tester.scrollUntilVisible(
            checkbox,
            350,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
          await tester.tap(checkbox);
          await tester.pump();
          await tester.tap(button);
          await tester.pump();
          expect(api.calls, isEmpty);
          expect(find.text(l.errProfileCpf), findsOneWidget);
          final cpf = find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.labelText == l.onboardingCpfLabel,
          );
          await tester.scrollUntilVisible(
            cpf,
            -350,
            scrollable: find.byType(Scrollable).first,
          );
          for (final invalid in [
            '00000000000',
            '11111111111',
            '52998224724',
            '52998224715',
          ]) {
            await tester.enterText(cpf, invalid);
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(find.text(l.errProfileCpf), findsOneWidget);
            expect(find.byType(CheckboxListTile), findsOneWidget);
            expect(api.calls, isEmpty);
          }
          await tester.enterText(cpf, '52998224725');
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(api.calls, isEmpty);
          expect(find.byType(CheckboxListTile), findsNothing);
          expect(find.text(l.onboardingBodyFormTitle), findsOneWidget);
          final birthDate = find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.labelText == l.profileFieldBirthDate,
          );
          await tester.ensureVisible(birthDate);
          await tester.enterText(birthDate, '15031990');
          expect(
            tester.widget<TextField>(birthDate).controller!.text,
            '15/03/1990',
          );
          await tester.tap(find.byIcon(Icons.calendar_month_outlined));
          await tester.pumpAndSettle();
          expect(find.byType(DatePickerDialog), findsOneWidget);
          await tester.tap(
            find.text(
              MaterialLocalizations.of(
                tester.element(find.byType(DatePickerDialog)),
              ).okButtonLabel,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<CheckboxListTile>(find.byType(CheckboxListTile))
                .value,
            isTrue,
          );
          await tester.tap(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(api.calls, ['profile', 'terms']);
          expect(api.accepted, isTrue);
          expect(controller.state.step, OnboardingStep.mainGoal);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
        }
      },
    );
  }
}
