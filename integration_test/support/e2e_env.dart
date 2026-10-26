/// Configuração dos testes integrados, passada pelo scripts/e2e/run.sh via --dart-define
/// (celular: localhost via `adb reverse`; emulador: 10.0.2.2, que é o padrão abaixo).
abstract final class E2eEnv {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');
  static const mailpitUrl = String.fromEnvironment('E2E_MAILPIT_URL', defaultValue: 'http://10.0.2.2:8025');

  /// Usuário semeado (seed_user.py): onboarding completo, treino ativo e assinatura válida.
  static const seededEmail = String.fromEnvironment('E2E_EMAIL');
  static const seededPassword = String.fromEnvironment('E2E_PASSWORD');

  /// Domínio exclusivo dos testes — o `seed_user.py --cleanup` apaga tudo que usa este domínio.
  static const emailDomain = 'e2e.personalia.test';

  static String uniqueEmail(String tag) =>
      'e2e-$tag-${DateTime.now().millisecondsSinceEpoch}@$emailDomain';

  /// Celular (DDD 11) único por execução, para a caixa de SMS do Mailpit não misturar testes.
  static String uniquePhone() {
    final suffix = (DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0');
    return '119$suffix';
  }
}
