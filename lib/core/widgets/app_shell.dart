import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/data/app_api.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.currentLocation});

  final Widget child;
  final String currentLocation;

  static const _tabs = [
    ('/home', Icons.home, 'Início'),
    ('/reports', Icons.bar_chart, 'Relatórios'),
    ('/referral', Icons.card_giftcard, 'Indicar'),
    ('/menu', Icons.menu, 'Menu'),
  ];

  int get _currentIndex {
    final index = _tabs.indexWhere((t) => currentLocation.startsWith(t.$1));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              tooltip: 'Tirar dúvidas',
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
          context.go(_tabs[index].$1);
        },
        items: [
          for (final (i, tab) in _tabs.indexed)
            BottomNavigationBarItem(
              icon: Icon(
                tab.$2,
                color: !isActive && i != 0 ? Colors.grey.shade300 : null,
              ),
              label: tab.$3,
            ),
        ],
      ),
    );
  }
}
