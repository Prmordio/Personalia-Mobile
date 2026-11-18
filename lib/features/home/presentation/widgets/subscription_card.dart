import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/app_api.dart';
import 'package:flutter/material.dart';

String _storeName(String? provider) =>
    provider == 'apple' ? 'App Store' : 'Google Play';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key, 
    required this.subscription,
    required this.onSubscribe,
  });
  final SubscriptionInfo subscription;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final dueDate = subscription.dueDate;
    final dueDateLabel = dueDate != null
        ? MaterialLocalizations.of(context).formatCompactDate(dueDate)
        : null;

    final l = context.l10n;
    String emoji;
    String title;
    String? subtitle;
    if (subscription.isFreeTrial) {
      emoji = '🎁';
      title = l.subscriptionFreeTrial;
      subtitle = dueDateLabel != null
          ? l.subscriptionValidUntil(dueDateLabel)
          : null;
    } else if (subscription.isInGracePeriod) {
      emoji = '⚠️';
      title = l.subscriptionPaymentPending;
      subtitle = dueDateLabel != null
          ? l.subscriptionGraceUntil(_storeName(subscription.provider), dueDateLabel)
          : null;
    } else if (subscription.isRenewalCanceled) {
      emoji = '⏳';
      title = l.subscriptionRenewalCanceled;
      subtitle = dueDateLabel != null
          ? l.subscriptionAccessUntil(dueDateLabel)
          : null;
    } else if (subscription.isValid) {
      emoji = '✅';
      title = l.subscriptionActive;
      subtitle = dueDateLabel != null
          ? l.subscriptionNextCharge(dueDateLabel)
          : null;
    } else {
      emoji = '⚠️';
      title = l.subscriptionInactive;
      subtitle = l.subscriptionSignupPrompt;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          // Pagamento pendente pede ação do usuário: destaca em laranja.
                          color: subscription.isInGracePeriod
                              ? AppColors.orange
                              : AppColors.blue,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!subscription.isValid) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onSubscribe,
                child: Text(l.subscriptionButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
