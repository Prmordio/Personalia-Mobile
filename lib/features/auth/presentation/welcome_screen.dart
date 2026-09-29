import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../state/biometric_login_service.dart';

/// Porta de entrada do app:
/// - "Entrar com biometria" (quando ativada neste aparelho) — o prompt abre sozinho na
///   primeira vez que a tela aparece.
/// - "Entrar" com email + senha.
/// - "Já uso o PersonalIA no WhatsApp": primeiro acesso no app (`/login/access`) — confirma
///   email E telefone e cria a senha. Também serve para redefinir a senha dessas contas.
/// - "Criar perfil": cadastro de quem ainda não usa o PersonalIA (por enquanto via telefone+OTP,
///   `/login/phone`; o backend decide entre Home e onboarding — ver GetOnboardingStatusUseCase).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Abre o prompt sozinho só uma vez por execução do app — depois de "Sair", não insiste.
  static bool _autoPrompted = false;

  bool _biometricEnabled = false;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final enabled = await ref.read(biometricLoginServiceProvider).isEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
    if (enabled && !_autoPrompted) {
      _autoPrompted = true;
      await _signInWithBiometric();
    }
  }

  Future<void> _signInWithBiometric() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);
    final result = await ref.read(biometricLoginServiceProvider).login();
    if (!mounted) return;
    setState(() => _signingIn = false);

    // success: o redirect do go_router leva para a Home.
    final message = switch (result) {
      BiometricLoginResult.invalidCredential => 'Sua biometria expirou ou foi desativada. Entre com email e senha.',
      BiometricLoginResult.failed => 'Não foi possível entrar agora. Tente novamente.',
      _ => null,
    };
    if (result == BiometricLoginResult.invalidCredential || result == BiometricLoginResult.notEnabled) {
      setState(() => _biometricEnabled = false);
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              const _Logo(),
              const SizedBox(height: 56),
              if (_biometricEnabled) ...[
                ElevatedButton.icon(
                  onPressed: _signingIn ? null : _signInWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Entrar com biometria'),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () => context.push('/login/password'),
                child: const Text('Entrar com email e senha'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => context.push('/login/access'),
                child: const Text('Já uso o PersonalIA no WhatsApp'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login/phone', extra: {'isNewUser': true}),
                child: const Text('Ainda não uso o PersonalIA — criar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
          children: [
            TextSpan(text: 'PERSONAL', style: TextStyle(color: AppColors.blue)),
            TextSpan(text: 'IA', style: TextStyle(color: AppColors.orange)),
          ],
        ),
      ),
    );
  }
}
