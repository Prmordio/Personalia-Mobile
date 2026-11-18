import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/app_api.dart';
import 'package:flutter/material.dart';

class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip});
  final DailyTip tip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dailyTipTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(tip.texto ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
