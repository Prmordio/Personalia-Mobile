import '../../../../core/l10n/l10n.dart';
import '../../data/app_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressCard extends ConsumerWidget {
  const ProgressCard({super.key, required this.progressAsync, this.isActive = true});
  final AsyncValue<ProgressInfo> progressAsync;
  final bool isActive;

  Future<void> _showUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    ProgressInfo? current,
  ) async {
    final weightController = TextEditingController(
      text: current?.currentWeight != null ? '${current!.currentWeight}' : '',
    );
    final heightController = TextEditingController(
      text: current?.currentHeight != null ? '${current!.currentHeight}' : '',
    );

    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.updateMeasuresTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.weightLabel,
                hintText: l.weightHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.heightLabel,
                hintText: l.heightHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancelar),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.salvar),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(heightController.text.replaceAll(',', '.'));

    if (weight == null && height == null) return;

    try {
      await ref
          .read(appApiProvider)
          .updateProgress(weight: weight, height: height);
      ref.invalidate(progressProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errSaveMeasures)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = progressAsync.asData?.value;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? () => _showUpdateDialog(context, ref, current) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.progressTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              progressAsync.when(
                data: (progress) {
                  if (progress.currentWeight == null &&
                      progress.currentHeight == null) {
                    return Text(context.l10n.progressAddMeasures);
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProgressStat(
                        label: context.l10n.progressWeight,
                        value: progress.currentWeight != null
                            ? '${progress.currentWeight} kg'
                            : '—',
                      ),
                      _ProgressStat(
                        label: context.l10n.progressHeight,
                        value: progress.currentHeight != null
                            ? '${progress.currentHeight} cm'
                            : '—',
                      ),
                      _ProgressStat(
                        label: context.l10n.progressLast90Days,
                        value: progress.weightLostPercent != null
                            ? '${progress.weightLostPercent! > 0 ? '-' : '+'}${progress.weightLostPercent!.abs()}%'
                            : '—',
                        valueColor:
                            progress.weightLostPercent != null &&
                                progress.weightLostPercent! > 0
                            ? Colors.green
                            : null,
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, stackTrace) =>
                    Text(context.l10n.errLoadProgress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
