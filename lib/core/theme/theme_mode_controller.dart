import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class ThemePreferenceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceThemePreferenceStore implements ThemePreferenceStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'appearance_theme_mode';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._store) : super(ThemeMode.system);
  final ThemePreferenceStore _store;
  bool _changed = false;

  Future<void> load() async {
    try {
      final saved = await _store.read();
      if (!mounted || _changed) return;
      state = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // A missing/unavailable preference must not prevent opening the app.
    }
  }

  Future<void> select(ThemeMode mode) async {
    _changed = true;
    await _store.write(mode.name);
    if (mounted) state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    final controller = ThemeModeController(DeviceThemePreferenceStore());
    controller.load();
    return controller;
  },
);
