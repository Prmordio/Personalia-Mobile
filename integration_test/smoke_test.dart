import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'support/app_driver.dart';

/// Confere a cadeia toda (build, emulador, app → gateway local) antes dos fluxos maiores.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app abre deslogado na tela de login', (tester) async {
    final driver = AppDriver(tester);
    await driver.launchLoggedOut();

    await driver.waitFor(find.text(driver.l10n.loginCreateAccount));
  });
}
