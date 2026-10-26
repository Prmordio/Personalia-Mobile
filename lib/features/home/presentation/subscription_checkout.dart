import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/billing/store_billing_controller.dart';
import '../data/app_api.dart';

/// Uses the store of the device; existing Mercado Pago plans keep their access.
Future<void> openSubscriptionCheckout(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    final subscription = await ref.read(appApiProvider).getSubscription();
    if (subscription.isValid && !subscription.isFreeTrial) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.subscriptionAlreadyActive)),
      );
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const StoreSubscriptionSheet(),
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.errGeneratePayment)));
  }
}

class StoreSubscriptionSheet extends ConsumerStatefulWidget {
  const StoreSubscriptionSheet({super.key});
  @override
  ConsumerState<StoreSubscriptionSheet> createState() =>
      _StoreSubscriptionSheetState();
}

class _StoreSubscriptionSheetState
    extends ConsumerState<StoreSubscriptionSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(storeBillingProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeBillingProvider);
    final controller = ref.read(storeBillingProvider.notifier);
    final l = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.storePlansTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (state.busy) const LinearProgressIndicator(),
                if (state.error != null)
                  Text(
                    context.resolveMessage(state.error) ?? l.storeUnavailable,
                  ),
                if (state.success) Text(l.storePurchaseConfirmed),
                for (final product in state.products)
                  ListTile(
                    title: Text(product.title),
                    subtitle: Text(product.description),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: !state.busy && state.canPurchase
                          ? () => controller.buy(product)
                          : null,
                      child: Text(
                        _priceWithPeriod(l, product.id, product.price),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(l.storeAutoRenewalNotice),
                if (controller.termsUrl != null &&
                    controller.termsUrl!.startsWith('https://'))
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(controller.termsUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l.storeTerms),
                  ),
                if (controller.privacyUrl != null &&
                    controller.privacyUrl!.startsWith('https://'))
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(controller.privacyUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l.storePrivacy),
                  ),
                TextButton(
                  onPressed: state.busy ? null : controller.restore,
                  child: Text(l.storeRestore),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      Theme.of(context).platform == TargetPlatform.iOS
                          ? 'https://apps.apple.com/account/subscriptions'
                          : 'https://play.google.com/store/account/subscriptions',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(l.storeManage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Apple exige o período junto do preço (3.1.2); os IDs dos produtos indicam o plano.
String _priceWithPeriod(AppLocalizations l, String productId, String price) {
  if (productId.contains('yearly')) return l.storePricePerYear(price);
  if (productId.contains('monthly')) return l.storePricePerMonth(price);
  return price;
}

/// Mostrado quando o "Gerar meu treino" é recusado por falta de assinatura.
Future<void> showSubscriptionRequiredDialog(
  BuildContext context,
  WidgetRef ref,
) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.subscriptionRequiredTitle),
      content: Text(l.subscriptionRequiredDesc),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l.btnNotNow),
        ),
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
