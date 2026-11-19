import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';

/// Sem nenhuma interface de rede ativa (Wi-Fi, dados, cabo...). Não garante internet de
/// fato, mas cobre o caso comum da academia sem sinal.
bool isOfflineResult(List<ConnectivityResult> results) =>
    results.isEmpty || results.every((r) => r == ConnectivityResult.none);

/// `true` quando o aparelho tem alguma rede. Começa como online (sem piscar banner na
/// abertura) e segue as mudanças do sistema.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    yield !isOfflineResult(await connectivity.checkConnectivity());
  } catch (_) {
    yield true;
  }
  yield* connectivity.onConnectivityChanged.map((r) => !isOfflineResult(r)).distinct();
});

/// Faixa "Você está offline" acima do app. O treino continua funcionando (o cache local
/// guarda as séries e envia quando a conexão volta).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).asData?.value ?? true;
    if (online) return child;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: colors.inverseSurface,
          child: SafeArea(
            bottom: false,
            child: Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: colors.onInverseSurface),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.offlineBanner,
                        style: TextStyle(color: colors.onInverseSurface, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // A faixa já ocupa a área do status bar; as telas abaixo não precisam do recuo.
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}
