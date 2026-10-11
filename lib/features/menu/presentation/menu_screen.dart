import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../auth/state/biometric_login_service.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = [
      (l.menuCurrentWorkout, Icons.fitness_center, '/workout/current'),
      (l.menuHistory, Icons.history, '/workout/last'),
      (l.menuSearchMachine, Icons.photo_camera, '/assistant?machine=1'),
      (l.menuAskDoubt, Icons.chat_bubble_outline, '/assistant'),
      (l.menuUpdateProfile, Icons.person, '/account/profile'),
      (l.menuTrainingPreferences, Icons.tune, '/account/preferences'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.menuTitle)),
      body: ListView(
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.$2),
              title: Text(item.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(item.$3),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l.menuAppearance),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeModeProvider),
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l.appearanceSystem),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l.appearanceLight)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l.appearanceDark)),
              ],
              onChanged: (mode) async {
                if (mode == null) return;
                try {
                  await ref.read(themeModeProvider.notifier).select(mode);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.errAppearanceSave)),
                    );
                  }
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.menuLanguage),
            trailing: _LanguageDropdown(),
          ),
          const _BiometricToggle(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l.menuLogout, style: const TextStyle(color: Colors.red)),
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

class _LanguageDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(localeProvider);

    return DropdownButton<Locale?>(
      value: locale,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: null, child: Text(l.langSystem)),
        DropdownMenuItem(value: const Locale('pt'), child: Text(l.langPortuguese)),
        DropdownMenuItem(value: const Locale('en'), child: Text(l.langEnglish)),
        DropdownMenuItem(value: const Locale('es'), child: Text(l.langSpanish)),
      ],
      onChanged: (selected) async {
        try {
          await ref.read(localeProvider.notifier).select(selected);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.errLanguageSave)),
            );
          }
        }
      },
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
        SnackBar(content: Text(context.l10n.errBiometricToggleFailed)),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null || !_available) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: Text(context.l10n.biometricToggleTitle),
      subtitle: Text(context.l10n.biometricToggleSubtitle),
      value: _enabled!,
      onChanged: _busy ? null : _toggle,
    );
  }
}
