import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../state/biometric_login_service.dart';

/// Logo depois de um login com senha, pergunta uma vez se o usuário quer entrar com
/// biometria das próximas vezes (só se o aparelho tiver biometria e ela ainda não estiver ativa).
class BiometricOfferGate extends ConsumerStatefulWidget {
  const BiometricOfferGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BiometricOfferGate> createState() => _BiometricOfferGateState();
}

class _BiometricOfferGateState extends ConsumerState<BiometricOfferGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  Future<void> _maybeOffer() async {
    if (!ref.read(biometricOfferPendingProvider)) return;
    ref.read(biometricOfferPendingProvider.notifier).state = false;

    final service = ref.read(biometricLoginServiceProvider);
    if (!await service.canEnable() || !mounted) return;

    final l = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.biometricOfferTitle),
        content: Text(l.biometricOfferDesc),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l.agoraNao)),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l.ativar)),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    final enabled = await service.enable();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? context.l10n.biometricEnabled : context.l10n.errBiometricActivateFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
