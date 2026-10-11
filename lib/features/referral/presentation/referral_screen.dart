import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../../core/l10n/l10n.dart';
import '../../home/data/app_api.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final referralAsync = ref.watch(referralProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.referralTitle)),
      body: referralAsync.when(
        data: (referral) {
          if (!referral.eligible) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.referralNotEligible, textAlign: TextAlign.center),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(l.referralYourCoupon, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    referral.code ?? '',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        if (referral.inviteLink != null) {
                          Share.share(referral.inviteLink!);
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: Text(l.referralShareLink),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(l.errLoadReferral)),
      ),
    );
  }
}
