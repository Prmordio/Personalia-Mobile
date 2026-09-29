import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../auth/state/biometric_login_service.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static const _items = [
    ('Meu Treino Atual', Icons.fitness_center, '/workout/current'),
    ('Histórico', Icons.history, '/workout/last'),
    ('Pesquisar máquina', Icons.photo_camera, '/assistant?machine=1'),
    ('Tirar dúvidas', Icons.chat_bubble_outline, '/assistant'),
    ('Atualizar Meu Perfil', Icons.person, '/account/profile'),
    ('Preferências de Treino', Icons.tune, '/account/preferences'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          for (final item in _items)
            ListTile(
              leading: Icon(item.$2),
              title: Text(item.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(item.$3),
            ),
          const Divider(),
          const _BiometricToggle(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(tokenStorageProvider).clear();
              ref.read(authRefreshProvider).value++;
            },
          ),
        ],
      ),
    );
  }
}

/// Liga/desliga o login por biometria neste aparelho. Some se o aparelho não tiver biometria.
class _BiometricToggle extends ConsumerStatefulWidget {
  const _BiometricToggle();

  @override
  ConsumerState<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<_BiometricToggle> {
  bool? _enabled;
  bool _available = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(biometricLoginServiceProvider);
    final enabled = await service.isEnabled();
    final available = enabled || await service.canEnable();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _available = available;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    final service = ref.read(biometricLoginServiceProvider);
    var ok = true;
    if (value) {
      ok = await service.enable();
    } else {
      await service.disable();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ativar a biometria. Tente novamente.')),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null || !_available) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('Entrar com biometria'),
      subtitle: const Text('Digital ou rosto em vez da senha'),
      value: _enabled!,
      onChanged: _busy ? null : _toggle,
    );
  }
}
