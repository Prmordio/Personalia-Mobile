import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/password_text_field.dart';
import '../state/auth_controller.dart';
import '../state/biometric_login_service.dart';
import '../state/password_login_controller.dart';

class PasswordLoginScreen extends ConsumerStatefulWidget {
  const PasswordLoginScreen({super.key});
  @override
  ConsumerState<PasswordLoginScreen> createState() =>
      _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends ConsumerState<PasswordLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static bool _autoPrompted = false;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_autoPrompted) return;
    try {
      final service = ref.read(biometricLoginServiceProvider);
      final enabled = await service.isEnabled();
      if (!mounted || !enabled || _autoPrompted) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true) ||
          ref.read(passwordLoginControllerProvider).loading) {
        return;
      }
      _autoPrompted = true;
      setState(() => _signingIn = true);
      final result = await service.login();
      if (!mounted) return;
      final message = switch (result) {
        BiometricLoginResult.invalidCredential =>
          context.l10n.errAuthBiometricExpired,
        BiometricLoginResult.failed => context.l10n.errAuthBiometricFailed,
        _ => null,
      };
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      // Missing/unavailable native services leave email and password available.
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordLoginControllerProvider);
    final controller = ref.read(passwordLoginControllerProvider.notifier);
    final l = context.l10n;
    final loading = state.loading || _signingIn;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                    children: [
                      TextSpan(
                        text: 'PERSONAL',
                        style: TextStyle(color: AppColors.blue),
                      ),
                      TextSpan(
                        text: 'IA',
                        style: TextStyle(color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                l.passwordLoginTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              AutofillGroup(
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      enabled: !loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: InputDecoration(
                        hintText: l.onboardingEmailHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AbsorbPointer(
                      absorbing: loading,
                      child: PasswordTextField(
                        controller: _passwordController,
                        hintText: l.passwordHint,
                        autofillHints: const [AutofillHints.password],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.resolveMessage(state.error)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () => controller.submit(
                        _emailController.text.trim(),
                        _passwordController.text,
                      ),
                child: loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      )
                    : Text(l.entrar),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: loading
                    ? null
                    : () => context.push('/login/password/forgot'),
                child: Text(l.forgotPasswordLink),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: loading
                    ? null
                    : () {
                        ref.invalidate(loginControllerProvider);
                        context.push('/login/register');
                      },
                child: Text(l.loginCreateAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
