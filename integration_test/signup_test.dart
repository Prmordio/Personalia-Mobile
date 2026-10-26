import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personalia_app/features/onboarding/presentation/onboarding_screen.dart';
import 'support/app_driver.dart';
import 'support/backend.dart';
import 'support/e2e_env.dart';
import 'support/mailbox.dart';

/// Cadastro por email no app real, contra o backend local: código do email e do SMS lidos no
/// Mailpit (notifier com SMS_TRANSPORT=mailbox).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final mailbox = Mailbox();
  final backend = Backend();
  const password = 'senha-forte-123';

  Future<void> openSignup(AppDriver driver) async {
    await driver.launchLoggedOut();
    await driver.tapText(driver.l10n.loginCreateAccount);
    await driver.waitFor(driver.fieldWithHint(driver.l10n.onboardingEmailHint));
  }

  /// Email → código do email (lido no Mailpit) → passo da senha.
  Future<void> confirmEmail(AppDriver driver, String email) async {
    final l = driver.l10n;
    await driver.enterText(driver.fieldWithHint(l.onboardingEmailHint), email);
    await driver.tapText(l.appAccessSendCodeAction);
    await driver.waitFor(driver.fieldWithHint(l.appAccessCodeHint));
    final code = await mailbox.waitForCode(email);
    await driver.enterText(driver.fieldWithHint(l.appAccessCodeHint), code);
    await driver.tapText(l.appAccessConfirmCode);
    await driver.waitFor(driver.fieldWithHint(l.appAccessRepeatPasswordHint));
  }

  Future<void> fillPassword(AppDriver driver, String value, {String? confirmation, String phone = ''}) async {
    final l = driver.l10n;
    await driver.enterText(driver.fieldWithHint(l.onboardingPasswordHint), value);
    await driver.enterText(driver.fieldWithHint(l.appAccessRepeatPasswordHint), confirmation ?? value);
    await driver.enterText(driver.fieldWithHint(l.signupPhoneOptionalHint), phone);
    await driver.tapText(l.signupCreateAccount);
  }

  testWidgets('1. cadastro — caminho feliz (sem telefone) leva ao onboarding', (tester) async {
    final driver = AppDriver(tester);
    final email = E2eEnv.uniqueEmail('signup');

    await openSignup(driver);
    await confirmEmail(driver, email);
    await fillPassword(driver, password);

    await driver.waitFor(find.byType(OnboardingScreen));
    // A conta existe de verdade no backend e entra com a senha criada.
    expect(await backend.login(email, password), isNotEmpty);
  });

  testWidgets('1.1 cadastro — erros de validação e do backend', (tester) async {
    final driver = AppDriver(tester);
    await openSignup(driver);
    final l = driver.l10n;
    final emailField = driver.fieldWithHint(l.onboardingEmailHint);

    // Email malformado: barrado no app, sem chamar o backend.
    await driver.enterText(emailField, 'sem-arroba');
    await driver.tapText(l.appAccessSendCodeAction);
    await driver.expectText(l.errAppAccessEmail);

    // Email que já tem conta (o usuário semeado): 409 do backend, app oferece ir para o login.
    await driver.enterText(emailField, E2eEnv.seededEmail);
    await driver.tapText(l.appAccessSendCodeAction);
    await driver.expectText('Este email já tem uma conta');
    await driver.waitFor(find.text(l.signupGoToLogin));

    // Código errado: o backend recusa e o app continua no passo do código.
    final email = E2eEnv.uniqueEmail('signup-errors');
    await driver.enterText(emailField, email);
    await driver.tapText(l.appAccessSendCodeAction);
    await driver.waitFor(driver.fieldWithHint(l.appAccessCodeHint));
    await driver.enterText(driver.fieldWithHint(l.appAccessCodeHint), '000000');
    await driver.tapText(l.appAccessConfirmCode);
    await driver.expectText('Código inválido ou expirado');

    // Com o código certo, os erros do passo da senha (todos barrados antes de criar a conta).
    final code = await mailbox.waitForCode(email);
    await driver.enterText(driver.fieldWithHint(l.appAccessCodeHint), code);
    await driver.tapText(l.appAccessConfirmCode);
    await driver.waitFor(driver.fieldWithHint(l.appAccessRepeatPasswordHint));

    await fillPassword(driver, 'curta');
    await driver.expectText(l.errAuthPasswordTooShort);
    await fillPassword(driver, password, confirmation: 'outra-senha-123');
    await driver.expectText(l.errPasswordMismatch);
    await fillPassword(driver, password, phone: '1234');
    await driver.expectText(l.errSignupPhoneInvalid);

    // Nada disso criou conta.
    await expectLater(backend.login(email, password), throwsA(anything));
  });

  testWidgets('1.2 cadastro com telefone — código chega por email e por SMS', (tester) async {
    final driver = AppDriver(tester);
    final email = E2eEnv.uniqueEmail('signup-sms');
    final phone = E2eEnv.uniquePhone();
    final smsBox = Mailbox.smsAddress(phone);

    await openSignup(driver);
    await confirmEmail(driver, email);
    final emails = await mailbox.messagesTo(email);
    expect(emails, hasLength(1), reason: 'um email com o código de cadastro');
    expect(emails.first['Subject'], contains('confirme seu email'));

    await fillPassword(driver, password, phone: phone);
    final l = driver.l10n;
    final smsCodeField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == l.appAccessCodeHint,
    );
    await driver.waitFor(smsCodeField);
    final smsCode = await mailbox.waitForCode(smsBox);
    expect(await mailbox.messagesTo(smsBox), hasLength(1), reason: 'um SMS com o código do telefone');

    // Antes de confirmar o SMS a conta ainda não existe.
    await expectLater(backend.login(email, password), throwsA(anything));

    await driver.enterText(smsCodeField, smsCode);
    await driver.tapText(l.appAccessConfirmCode);

    await driver.waitFor(find.byType(OnboardingScreen));
    expect(await backend.login(email, password), isNotEmpty);
  });
}
