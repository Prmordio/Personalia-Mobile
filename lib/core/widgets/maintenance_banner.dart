import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../remote_config/feature_flags.dart';

/// Faixa no topo com o aviso publicado em `maintenance_message` (Remote Config), para
/// avisar instabilidade (assistente, WhatsApp, pagamentos) sem release de loja.
class MaintenanceBanner extends ConsumerWidget {
  const MaintenanceBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref
        .watch(featureFlagsProvider)
        .maintenanceFor(Localizations.localeOf(context).languageCode);
    if (message == null) return child;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: colors.tertiaryContainer,
          child: SafeArea(
            bottom: false,
            child: Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
