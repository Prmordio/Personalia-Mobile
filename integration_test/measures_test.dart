import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'support/app_driver.dart';
import 'support/backend.dart';
import 'support/e2e_env.dart';

/// Atualizar medidas pelo card de progresso da home (PUT /app/progress → PhysicalMetricLog).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = Backend();

  testWidgets('5. atualizar peso e altura pelo card de progresso', (tester) async {
    final driver = AppDriver(tester);
    await driver.launchLoggedOut();
    await driver.loginWithPassword(E2eEnv.seededEmail, E2eEnv.seededPassword);
    final l = driver.l10n;

    await driver.tapText(l.progressTitle, timeout: const Duration(seconds: 45));
    await driver.waitFor(find.text(l.updateMeasuresTitle));
    await driver.enterText(driver.fieldWithHint(l.weightLabel), '82.5');
    await driver.enterText(driver.fieldWithHint(l.heightLabel), '179');
    await driver.tapText(l.salvar);
    await driver.waitForGone(find.text(l.updateMeasuresTitle));

    // A home recarrega o progresso com o peso novo, e o backend gravou as duas medidas.
    await driver.expectText('82.5');
    final token = await backend.login(E2eEnv.seededEmail, E2eEnv.seededPassword);
    final progress = await backend.get('/app/progress', token) as Map;
    expect(progress['currentWeight'], 82.5);
    expect(progress['currentHeight'], 179);
  });
}
