import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n.dart';
import '../data/app_api.dart';

/// Abre o checkout do Mercado Pago no navegador (botão "Assinar").
Future<void> openSubscriptionCheckout(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    final url = await ref.read(appApiProvider).getCheckoutUrl();
    if (url == null) {
      ref.invalidate(subscriptionProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.subscriptionAlreadyActive)));
      return;
    }
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l.errOpenPaymentPage)));
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.errGeneratePayment)));
  }
}

/// Mostrado quando o "Gerar meu treino" é recusado por falta de assinatura.
Future<void> showSubscriptionRequiredDialog(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.subscriptionRequiredTitle),
      content: Text(l.subscriptionRequiredDesc),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l.btnNotNow)),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openSubscriptionCheckout(context, ref);
          },
          child: Text(l.subscriptionButton),
        ),
      ],
    ),
  );
}
