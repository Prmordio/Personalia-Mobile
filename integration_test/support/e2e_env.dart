/// Configuração dos testes integrados, passada pelo scripts/e2e/run.sh via --dart-define
/// (celular: localhost via `adb reverse`; emulador: 10.0.2.2, que é o padrão abaixo).
abstract final class E2eEnv {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');
  static const mailpitUrl = String.fromEnvironment('E2E_MAILPIT_URL', defaultValue: 'http://10.0.2.2:8025');

  /// Usuários semeados (seed_user.py), um por arquivo de teste: "measures=email;swap=email".
  /// Um fluxo (treino finalizado, troca permanente no plano) não muda o ponto de partida do
  /// outro, mesmo rodando todos no mesmo app (all_test.dart).
  static const _seededUsers = String.fromEnvironment('E2E_USERS');
  static const seededPassword = String.fromEnvironment('E2E_PASSWORD');

  /// Email do usuário semeado para o arquivo [suite] (onboarding completo, treino ativo e
  /// assinatura válida).
  static String seededEmail(String suite) {
    for (final entry in _seededUsers.split(';')) {
      final [name, email] = entry.split('=');
      if (name == suite) return email;
    }
    throw StateError('Sem usuário semeado para "$suite" em E2E_USERS — rode pelo scripts/e2e/run.sh.');
  }

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
