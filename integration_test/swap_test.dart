import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'support/app_driver.dart';
import 'support/backend.dart';
import 'support/e2e_env.dart';

/// Trocas no plano do usuário semeado (seed_user.py): "Treino A" (Supino reto, Remada curvada) é
/// o de hoje; "Treino B" tem Agachamento livre, Leg press e Puxada E2E. As alternativas da
/// Puxada E2E vêm fixas do cache do agent-v2 (Puxada aberta E2E, Remada baixa E2E), sem IA.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = Backend();
  const swapped = 'Puxada E2E';

  /// Login → "Trocar treino" na home → escolhe o Treino B, que abre o treino de hoje. Abrir o dia
  /// já grava a sessão no aparelho, então cada teste começa sem treino em andamento.
  Future<void> switchToWorkoutB(AppDriver driver) async {
    await driver.launchLoggedOut(clearWorkoutSessions: true);
    await driver.loginWithPassword(E2eEnv.seededEmail('swap'), E2eEnv.seededPassword);
    final l = driver.l10n;
    await driver.tapText(l.btnSwitchWorkout, timeout: const Duration(seconds: 45));
    await driver.waitFor(find.text(l.chooseWorkoutDayTitle));
    await driver.tapText('Treino B');
    await driver.waitFor(find.text(swapped));
  }

  /// O botão "Trocar" do card do exercício [name] (cada card tem o seu).
  Future<void> tapSwapOn(AppDriver driver, String name) async {
    final card = find.ancestor(of: find.text(name), matching: find.byType(Card));
    final button = driver.onTopRoute(find.descendant(of: card, matching: find.text(driver.l10n.btnSwap)));
    await driver.waitFor(button);
    await driver.tester.ensureVisible(button.first);
    await driver.tester.pump();
    await driver.tester.tap(button.first);
    await driver.tester.pump(const Duration(milliseconds: 300));
  }

  /// Escolhe a alternativa [alternative] para a Puxada E2E, faz o exercício trocado e responde o
  /// "tornar permanente?" — o app só pergunta depois que o exercício trocado é finalizado.
  Future<void> swapExercise(AppDriver driver, String alternative, {required bool permanent}) async {
    final l = driver.l10n;
    await tapSwapOn(driver, swapped);
    await driver.waitFor(find.text(l.swapExerciseTitle));
    await driver.waitFor(find.text('Remada baixa E2E'));
    await driver.tapText(alternative);
    await driver.waitFor(find.text(l.exerciseSwapped(swapped)));
    // A tela de troca ainda sai animada por cima da lista e engole o toque no card.
    await driver.waitForGone(find.text(l.swapExerciseTitle));
    expect(find.text(l.makePermanentTitle), findsNothing, reason: 'só pergunta depois de fazer o exercício');

    await driver.tapText(alternative);
    await driver.completeExercise(sets: 3, weight: '20');
    await driver.waitFor(find.text(l.makePermanentTitle));
    await driver.tapText(permanent ? l.btnYesChangePlan : l.btnThisTimeOnly);
    await driver.waitForGone(find.text(l.makePermanentTitle));
  }

  /// O exercício feito vai para a seção "Mostrar concluídos", que começa recolhida.
  Future<void> showFinished(AppDriver driver) => driver.tapText(driver.l10n.showCompleted(1));

  Future<List<String>> planExercises(String dayName) async {
    final token = await backend.login(E2eEnv.seededEmail('swap'), E2eEnv.seededPassword);
    final current = await backend.get('/app/workout/current', token) as Map;
    final days = (current['lastWorkout']['days'] as List).cast<Map>();
    final day = days.singleWhere((d) => d['dayName'] == dayName);
    return [for (final e in day['exercises'] as List) (e as Map)['nome'] as String];
  }

  testWidgets('6. trocar treino — outro dia do plano vale só para hoje, no app', (tester) async {
    final driver = AppDriver(tester);
    await switchToWorkoutB(driver);

    expect(find.text('Agachamento livre'), findsOneWidget);
    expect(find.text('Leg press'), findsOneWidget);
    expect(find.text('Supino reto'), findsNothing);

    // A troca é local (TodayDayOverride): o backend continua sugerindo o Treino A para hoje.
    final token = await backend.login(E2eEnv.seededEmail('swap'), E2eEnv.seededPassword);
    final today = await backend.get('/app/workout/today', token) as Map;
    expect(today['dayName'], 'Treino A');
  });

  testWidgets('7. trocar exercício só desta vez — muda o treino de hoje, não o plano', (tester) async {
    final driver = AppDriver(tester);
    await switchToWorkoutB(driver);

    await swapExercise(driver, 'Puxada aberta E2E', permanent: false);

    await showFinished(driver);
    await driver.waitFor(find.text('Puxada aberta E2E'));
    expect(find.text(driver.l10n.exerciseSwapped(swapped)), findsOneWidget);
    expect(await planExercises('Treino B'), contains(swapped));
  });

  testWidgets('8. trocar exercício permanente — o plano passa a ter o novo exercício', (tester) async {
    final driver = AppDriver(tester);
    await switchToWorkoutB(driver);

    await swapExercise(driver, 'Remada baixa E2E', permanent: true);

    await showFinished(driver);
    await driver.waitFor(find.text('Remada baixa E2E'));
    final exercises = await planExercises('Treino B');
    expect(exercises, contains('Remada baixa E2E'));
    expect(exercises, isNot(contains(swapped)));
    expect(exercises, containsAll(['Agachamento livre', 'Leg press']));
  });
}
