import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../features/home/data/app_api.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  static const _tabRoutes = [
    ('/home', Icons.home),
    ('/reports', Icons.bar_chart),
    ('/referral', Icons.card_giftcard),
    ('/menu', Icons.menu),
  ];

  int get _currentIndex {
    final index = _tabRoutes.indexWhere((t) => currentLocation.startsWith(t.$1));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tabLabels = [l.navHome, l.navReports, l.navReferral, l.navMenu];

    final subscriptionAsync = ref.watch(subscriptionProvider);
    // Considera ativa enquanto carrega (evita piscar de bloqueado para liberado).
    final isActive = subscriptionAsync.maybeWhen(
      data: (s) => s.isValid,
      orElse: () => true,
    );

    return Scaffold(
      body: child,
      // Chat de dúvidas disponível somente para assinantes.
      floatingActionButton: isActive
          ? FloatingActionButton(
              tooltip: l.navAssistantTooltip,
              onPressed: () => context.push('/assistant'),
              child: const Icon(Icons.chat_bubble_outline),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          // Sem assinatura, só a aba Início (índice 0) é permitida.
          if (!isActive && index != 0) return;
          context.go(_tabRoutes[index].$1);
        },
        items: [
          for (final (i, tab) in _tabRoutes.indexed)
            BottomNavigationBarItem(
              icon: Icon(
                tab.$2,
                color: !isActive && i != 0
                    ? Theme.of(context).colorScheme.outlineVariant
                    : null,
              ),
              label: tabLabels[i],
            ),
        ],
      ),
    );
  }
}
