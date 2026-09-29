import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      // Chat de dúvidas sempre à mão, em todas as abas.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tirar dúvidas',
        onPressed: () => context.push('/assistant'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => context.go(_tabs[index].$1),
        items: [
          for (final tab in _tabs) BottomNavigationBarItem(icon: Icon(tab.$2), label: tab.$3),
        ],
      ),
    );
  }
}
