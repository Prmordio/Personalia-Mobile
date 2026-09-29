import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_api.dart';

/// Abre o checkout do Mercado Pago no navegador (botão "Assinar").
Future<void> openSubscriptionCheckout(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final url = await ref.read(appApiProvider).getCheckoutUrl();
    if (url == null) {
      ref.invalidate(subscriptionProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Sua assinatura já está ativa ✅')));
      return;
    }
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('Não foi possível abrir a página de pagamento.')));
    }
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Não foi possível gerar o pagamento. Tente novamente.')));
  }
}

/// Mostrado quando o "Gerar meu treino" é recusado por falta de assinatura.
Future<void> showSubscriptionRequiredDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Assinatura necessária'),
      content: const Text(
        'Seu período grátis ou sua assinatura terminou. Assine o PersonalIA para gerar seu treino — '
        'depois de pagar, volte aqui e toque em "Gerar meu treino" de novo.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Agora não')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openSubscriptionCheckout(context, ref);
          },
          child: const Text('Assinar'),
        ),
      ],
    ),
  );
}
