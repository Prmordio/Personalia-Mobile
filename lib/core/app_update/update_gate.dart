import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../telemetry/app_telemetry.dart';
import 'app_update_controller.dart';
import 'version_policy.dart';

/// Envolve o app (MaterialApp.builder): versão abaixo da mínima → tela de bloqueio;
/// abaixo da recomendada → cartão "Atualizar / Agora não" (uma vez por versão).
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  String? _dismissed;
  bool _dismissedLoaded = false;

  @override
  void initState() {
    super.initState();
    ref.read(dismissedUpdateStoreProvider).read().then(
      (value) {
        if (!mounted) return;
        setState(() {
          _dismissed = value;
          _dismissedLoaded = true;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _dismissedLoaded = true);
      },
    );
  }

  Future<void> _dismiss(AppVersion target) async {
    setState(() => _dismissed = target.toString());
    AppTelemetry.instance.event('update_prompt_dismissed');
    try {
      await ref.read(dismissedUpdateStoreProvider).write(target.toString());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(updateStatusProvider).asData?.value ?? UpdateStatus.none;
    if (status.requirement == UpdateRequirement.required) {
      return const ForceUpdateScreen();
    }
    final target = status.target;
    final showPrompt = status.requirement == UpdateRequirement.recommended &&
        target != null &&
        _dismissedLoaded &&
        _dismissed != target.toString();
    if (!showPrompt) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(child: _UpdateCard(onLater: () => _dismiss(target))),
        ),
      ],
    );
  }
}

Future<void> _openStore(BuildContext context) async {
  AppTelemetry.instance.event('update_store_opened');
  await launchUrl(
    Uri.parse(StoreLinks.forPlatform(Theme.of(context).platform)),
    mode: LaunchMode.externalApplication,
  );
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.onLater});
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l.updateRecommendedTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text(l.updateRecommendedBody),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onLater, child: Text(l.updateLater)),
                FilledButton(onPressed: () => _openStore(context), child: Text(l.updateNow)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloqueio total: versão abaixo da mínima suportada pelo backend.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ExcludeSemantics(child: Icon(Icons.system_update, size: 72)),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l.updateRequiredTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(l.updateRequiredBody, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => _openStore(context), child: Text(l.updateNow)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
