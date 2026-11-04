import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'support/app_driver.dart';
import 'support/backend.dart';
import 'support/e2e_env.dart';
import 'support/mailbox.dart';

/// Exclusão de conta pelo app (exigência da App Store — o mesmo fluxo do vídeo para o review):
/// entrar → Menu → "Excluir conta" → modal "tem certeza?" → confirmar → volta ao login, e a
/// conta deixa de existir no backend. Usa uma conta própria, nunca o usuário semeado.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = Backend();
  final mailbox = Mailbox();
  const password = 'senha-forte-123';

  Future<void> loginAndOpenMenu(AppDriver driver, String email) async {
    await driver.launchLoggedOut();
    await driver.loginWithPassword(email, password);
    await driver.tapText(driver.l10n.navMenu);
    await driver.scrollTo(find.byKey(const Key('menu-delete-account')), anchor: find.text(driver.l10n.menuLogout));
  }

  testWidgets('6. excluir conta — cancelar mantém a conta; confirmar exclui e desloga', (tester) async {
    final driver = AppDriver(tester);
    final email = E2eEnv.uniqueEmail('delete');
    await backend.createOnboardedAccount(email, password, mailbox);

    await loginAndOpenMenu(driver, email);
    final l = driver.l10n;

    // Cancelar no modal: nada acontece, a conta continua entrando.
    await driver.tapText(l.menuDeleteAccount);
    await driver.waitFor(find.text(l.deleteAccountTitle));
    await driver.tapText(l.deleteAccountCancel);
    await driver.waitForGone(find.text(l.deleteAccountTitle));
    expect(await backend.login(email, password), isNotEmpty);

    // Confirmar: a conta é excluída e o app volta para a tela de entrada.
    await driver.tapText(l.menuDeleteAccount);
    await driver.waitFor(find.text(l.deleteAccountTitle));
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await driver.waitFor(find.text(l.loginCreateAccount), timeout: const Duration(seconds: 45));

    // No backend a conta não existe mais: o login com a mesma senha é recusado.
    await expectLater(backend.login(email, password), throwsA(anything));
  });
}
