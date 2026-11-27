import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../state/live_activity_permission.dart';

/// Aviso discreto na tela de descanso quando "Atividades ao Vivo" está desligado
/// no iOS — sem isso o cronômetro não aparece na tela de bloqueio nem na Dynamic Island.
class LiveActivityHint extends ConsumerStatefulWidget {
  const LiveActivityHint({super.key});

  @override
  ConsumerState<LiveActivityHint> createState() => _LiveActivityHintState();
}

class _LiveActivityHintState extends ConsumerState<LiveActivityHint>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    unawaited(ref.read(liveActivityHintProvider.notifier).refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(liveActivityHintProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(liveActivityHintProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        key: const ValueKey('live-activity-hint'),
        margin: EdgeInsets.zero,
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_clock, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.liveActivityHintMessage,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  children: [
                    TextButton(
                      onPressed: () => unawaited(controller.dismiss()),
                      child: Text(l10n.liveActivityHintDismiss),
                    ),
                    TextButton(
                      onPressed: () => unawaited(controller.openSettings()),
                      child: Text(l10n.ativar),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
