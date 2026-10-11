import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/password_text_field.dart';
import '../state/app_access_controller.dart';

/// Primeiro acesso no app (e redefinição de senha) para quem já usa o PersonalIA no WhatsApp:
/// confirma email E telefone antes de criar a senha.
class AppAccessScreen extends ConsumerStatefulWidget {
  const AppAccessScreen({super.key});

  @override
  ConsumerState<AppAccessScreen> createState() => _AppAccessScreenState();
}

class _AppAccessScreenState extends ConsumerState<AppAccessScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _phoneController,
      _emailController,
      _codeController,
      _passwordController,
      _confirmationController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appAccessControllerProvider);
    final controller = ref.read(appAccessControllerProvider.notifier);

    // Cada passo com código começa com o campo limpo.
    ref.listen(
      appAccessControllerProvider.select((s) => s.step),
      (_, _) => _codeController.clear(),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: state.loading
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _title(state.step),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (state.info != null) ...[
                Text(context.resolveMessage(state.info)!),
                const SizedBox(height: 16),
              ],
              ..._stepBody(state, controller),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.resolveMessage(state.error)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.loading
                    ? null
                    : () => _submit(state, controller),
                child: state.loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      )
                    : Text(_primaryLabel(context, state.step)),
              ),
              ..._secondaryActions(state, controller),
            ],
          ),
        ),
      ),
    );
  }

  String _title(AppAccessStep step) => switch (step) {
    AppAccessStep.start => context.l10n.appAccessTitle,
    AppAccessStep.emailCode => context.l10n.appAccessEmailCodeTitle,
    AppAccessStep.phoneCode => context.l10n.appAccessPhoneCodeTitle,
    AppAccessStep.confirmEmail => context.l10n.appAccessConfirmEmailTitle,
    AppAccessStep.password => context.l10n.appAccessPasswordTitle,
  };

  String _primaryLabel(BuildContext ctx, AppAccessStep step) => switch (step) {
    AppAccessStep.start => ctx.l10n.continuar,
    AppAccessStep.confirmEmail => ctx.l10n.appAccessSendCodeAction,
    AppAccessStep.password => ctx.l10n.appAccessSavePassword,
    _ => ctx.l10n.appAccessConfirmCode,
  };

  List<Widget> _stepBody(AppAccessState state, AppAccessController controller) {
    switch (state.step) {
      case AppAccessStep.start:
        return [
          Text(context.l10n.appAccessStartDesc),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(hintText: context.l10n.appAccessPhoneHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(hintText: context.l10n.onboardingEmailHint),
          ),
        ];
      case AppAccessStep.emailCode:
        return [_codeField()];
      case AppAccessStep.phoneCode:
        return [
          Text(context.l10n.appAccessPhoneCodeDesc),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: state.loading ? null : _openWhatsApp,
            icon: const Icon(Icons.chat),
            label: Text(context.l10n.appAccessOpenWhatsApp),
          ),
          const SizedBox(height: 16),
          _codeField(),
        ];
      case AppAccessStep.confirmEmail:
        if (_emailController.text.isEmpty) _emailController.text = state.email;
        return [
          Text(context.l10n.appAccessConfirmEmailDesc),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: context.l10n.onboardingEmailHint),
          ),
        ];
      case AppAccessStep.password:
        return [
          Text(context.l10n.appAccessPasswordDesc),
          const SizedBox(height: 16),
          PasswordTextField(
            controller: _passwordController,
            hintText: context.l10n.forgotPasswordNewPasswordHint,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 12),
          PasswordTextField(
            controller: _confirmationController,
            hintText: context.l10n.appAccessRepeatPasswordHint,
          ),
        ];
    }
  }

  Widget _codeField() {
    return TextField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: context.l10n.appAccessCodeHint,
        counterText: '',
      ),
    );
  }

  List<Widget> _secondaryActions(
    AppAccessState state,
    AppAccessController controller,
  ) {
    final actions = <Widget>[];
    void add(String label, VoidCallback onPressed) {
      actions
        ..add(const SizedBox(height: 8))
        ..add(
          TextButton(
            onPressed: state.loading ? null : onPressed,
            child: Text(label),
          ),
        );
    }

    if (state.step == AppAccessStep.emailCode) {
      if (state.phoneVerified) {
        add(context.l10n.appAccessFixEmail, controller.editEmail);
      } else {
        add(context.l10n.appAccessNoEmail, controller.useWhatsApp);
      }
    }
    if (state.step != AppAccessStep.start &&
        state.step != AppAccessStep.password) {
      add(context.l10n.appAccessRestart, () {
        _emailController.clear();
        controller.restart();
      });
    }
    return actions;
  }

  void _submit(AppAccessState state, AppAccessController controller) {
    switch (state.step) {
      case AppAccessStep.start:
        controller.start(
          _phoneController.text.trim(),
          _emailController.text.trim(),
        );
      case AppAccessStep.emailCode:
      case AppAccessStep.phoneCode:
        controller.verifyCode(_codeController.text.trim());
      case AppAccessStep.confirmEmail:
        controller.confirmEmail(_emailController.text.trim());
      case AppAccessStep.password:
        controller.complete(
          _passwordController.text,
          _confirmationController.text,
        );
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$whatsappBotNumber?text=${Uri.encodeComponent(appAccessWhatsAppMessage)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
