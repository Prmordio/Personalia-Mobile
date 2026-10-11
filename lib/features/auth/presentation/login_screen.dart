import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../state/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _ddiController = TextEditingController(text: '55');
  final _dddController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _ddiController.dispose();
    _dddController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isNewUser {
    final extra = GoRouterState.of(context).extra;
    return extra is Map && extra['isNewUser'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const _Logo(),
              const SizedBox(height: 40),
              if (state.step == LoginStep.phone)
                ..._phoneStep(state, controller),
              if (state.step == LoginStep.channel)
                ..._channelStep(state, controller),
              if (state.step == LoginStep.otp) ..._otpStep(state, controller),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.resolveMessage(state.error)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (state.info != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.resolveMessage(state.info)!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.send;
      default:
        return Icons.sms;
    }
  }

  String _channelLabel(String channel) {
    switch (channel) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'telegram':
        return 'Telegram';
      default:
        return 'SMS';
    }
  }

  List<Widget> _phoneStep(LoginState state, LoginController controller) {
    return [
      Text(
        _isNewUser ? context.l10n.loginCreateProfileTitle : context.l10n.loginSyncTitle,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        _isNewUser ? context.l10n.loginCreateProfileDesc : context.l10n.loginSyncDesc,
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: TextField(
              controller: _ddiController,
              keyboardType: TextInputType.phone,
              maxLength: 2,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'DDI',
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _dddController,
              keyboardType: TextInputType.phone,
              maxLength: 2,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'DDD',
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              decoration: const InputDecoration(
                hintText: '987654321',
                counterText: '',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: state.loading
            ? null
            : () => controller.submitPhone(
                '${_ddiController.text}${_dddController.text}${_phoneController.text}',
              ),
        child: state.loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              )
            : Text(context.l10n.continuar),
      ),
    ];
  }

  List<Widget> _channelStep(LoginState state, LoginController controller) {
    return [
      Text(
        context.l10n.loginHowToReceive,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 24),
      for (final channel in state.channels) ...[
        ElevatedButton.icon(
          onPressed: state.loading
              ? null
              : () => controller.selectChannel(channel),
          icon: Icon(_channelIcon(channel)),
          label: Text(context.l10n.loginReceiveVia(_channelLabel(channel))),
        ),
        const SizedBox(height: 12),
      ],
      TextButton(
        onPressed: controller.backToPhone,
        child: Text(context.l10n.voltar),
      ),
    ];
  }

  List<Widget> _otpStep(LoginState state, LoginController controller) {
    return [
      Text(
        context.l10n.loginEnterCode,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        context.l10n.loginCodeSentVia(_channelLabel(state.selectedChannel ?? 'whatsapp')),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(hintText: '000000'),
      ),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: state.loading
            ? null
            : () async {
                final ok = await controller.verifyCode(_codeController.text);
                if (ok && context.mounted) {
                  // O redirect do go_router (core/router/app_router.dart) cuida da navegação.
                }
              },
        child: state.loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              )
            : Text(context.l10n.entrar),
      ),
      TextButton(
        onPressed: state.loading ? null : controller.resendCode,
        child: Text(context.l10n.loginResendCode),
      ),
      TextButton(
        onPressed: controller.backToPhone,
        child: Text(context.l10n.loginUseOtherPhone),
      ),
    ];
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
