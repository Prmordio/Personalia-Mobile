import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'support/app_driver.dart';
import 'support/backend.dart';
import 'support/e2e_env.dart';

/// Treino do usuário semeado (seed_user.py): "Treino A" com Supino reto e Remada curvada,
/// 2 séries cada, descanso de 10s. Cobre iniciar o treino, registrar os exercícios, o timer de
/// descanso e finalizar — e confere no backend o que ficou gravado.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = Backend();
  final clockPattern = RegExp(r'^\d\d:\d\d$');

  /// Segundos no cronômetro do descanso (o mesmo "mm:ss" aparece no círculo e no botão).
  int clockSeconds() {
    final clock = find.byWidgetPredicate((w) => w is Text && clockPattern.hasMatch(w.data ?? ''));
    final text = (clock.evaluate().first.widget as Text).data!;
    final parts = text.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }

  Future<void> loginAndOpenTodayWorkout(AppDriver driver) async {
    await driver.launchLoggedOut();
    await driver.loginWithPassword(E2eEnv.seededEmail, E2eEnv.seededPassword);
    await driver.tapText(driver.l10n.workoutStart, timeout: const Duration(seconds: 45));
    await driver.waitFor(find.text('Supino reto'));
  }

  /// Conclui as séries com o descanso pulado, registra peso/observação e finaliza o exercício.
  Future<void> completeExercise(AppDriver driver, String name, {required String weight, String? note}) async {
    final l = driver.l10n;
    for (var set = 0; set < 2; set++) {
      await driver.tapText(l.restBtnStartRest);
      if (find.text(l.restEndRest).evaluate().isNotEmpty) {
        await driver.tapText(l.restEndRest);
      }
    }
    await driver.waitFor(find.text(l.restExerciseDone));
    await driver.enterText(driver.fieldWithHint(l.restWeightLabel), weight);
    if (note != null) {
      await driver.enterText(driver.fieldWithHint(l.restObservationLabel), note);
    }
    await driver.tapText(l.restBtnFinishExercise);
    await driver.waitForGone(find.text(l.restBtnFinishExercise));
  }

  testWidgets('2-4. iniciar treino, registrar exercícios, timer de descanso e finalizar', (tester) async {
    final driver = AppDriver(tester);

    // 2. Iniciar o treino: a home leva ao treino de hoje com os exercícios do plano.
    await loginAndOpenTodayWorkout(driver);
    expect(find.text('Remada curvada'), findsOneWidget);
    final l = driver.l10n;

    // 4. Timer: a 1ª série inicia o descanso de 10s, que corre, ganha +30s e pode ser encerrado.
    await driver.tapText('Supino reto');
    await driver.tapText(l.restBtnStartRest);
    await driver.waitFor(find.text(l.restStatusRest));
    final started = clockSeconds();
    expect(started, inInclusiveRange(1, 10));
    await driver.idle(const Duration(seconds: 3));
    expect(clockSeconds(), lessThan(started), reason: 'o descanso conta para baixo');

    final beforeAdd = clockSeconds();
    await driver.tapText('+30 s');
    await tester.pump(const Duration(milliseconds: 500));
    expect(clockSeconds(), greaterThanOrEqualTo(beforeAdd + 25), reason: '+30 s soma ao descanso');

    await driver.tapText(l.restEndRest);
    await driver.waitFor(find.text(l.restNextSet));

    // Sem peso o exercício não pode ser finalizado.
    await driver.tapText(l.restBtnStartRest);
    if (find.text(l.restEndRest).evaluate().isNotEmpty) {
      await driver.tapText(l.restEndRest);
    }
    await driver.waitFor(find.text(l.restExerciseDone));
    final finishButton = find.ancestor(of: find.text(l.restBtnFinishExercise), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(finishButton).onPressed, isNull);

    // 3. Registrar os exercícios: peso + observação.
    await driver.enterText(driver.fieldWithHint(l.restWeightLabel), '40');
    await driver.enterText(driver.fieldWithHint(l.restObservationLabel), 'e2e supino');
    await driver.tapText(l.restBtnFinishExercise);
    await driver.waitForGone(find.text(l.restBtnFinishExercise));

    await driver.tapText('Remada curvada');
    await completeExercise(driver, 'Remada curvada', weight: '30');

    // Finalizar o treino: com todos os exercícios concluídos o app já abre o resumo; senão,
    // passa pelo "Finalizar treino" + confirmação.
    final summary = driver.onTopRoute(find.text(l.btnFinishWithoutCard));
    await driver.idle(const Duration(seconds: 2));
    if (summary.evaluate().isEmpty) {
      await driver.tapText(l.btnFinishWorkout);
      await driver.tapText(l.sim);
    }
    await driver.tapText(l.btnFinishWithoutCard, timeout: const Duration(seconds: 45));
    await driver.idle(const Duration(seconds: 3));

    // O backend gravou a execução com os dois exercícios e os pesos informados.
    final token = await backend.login(E2eEnv.seededEmail, E2eEnv.seededPassword);
    final history = await backend.get('/app/workout/history', token) as List;
    expect(history, isNotEmpty, reason: 'execução registrada no histórico');
    final execution = history.first as Map;
    expect(execution['dayName'], 'Treino A');
    expect(execution['isToday'], isTrue);
    final exercises = {
      for (final e in execution['exercises'] as List) e['name']: e,
    };
    expect(exercises.keys, containsAll(['Supino reto', 'Remada curvada']));
    expect(exercises['Supino reto']['weight'].toString(), contains('40'));
    expect(exercises['Supino reto']['observation'], 'e2e supino');
    expect(exercises['Remada curvada']['weight'].toString(), contains('30'));
  });
}
