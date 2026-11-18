import '../../../../core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ViewPlanCard extends StatelessWidget {
  const ViewPlanCard({super.key, this.isActive = true});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.viewPlanTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.viewPlanDesc),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isActive
                  ? () => context.push('/workout/current')
                  : null,
              child: Text(context.l10n.viewPlanButton),
            ),
          ],
        ),
      ),
    );
  }
}
