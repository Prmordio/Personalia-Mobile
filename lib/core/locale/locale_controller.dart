import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class LocalePreferenceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceLocalePreferenceStore implements LocalePreferenceStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_locale';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

/// null = follow system locale
class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._store) : super(null);
  final LocalePreferenceStore _store;
  bool _changed = false;

  Future<void> load() async {
    try {
      final saved = await _store.read();
      if (!mounted || _changed) return;
      state = _fromCode(saved);
    } catch (_) {}
  }

  Future<void> select(Locale? locale) async {
    _changed = true;
    await _store.write(locale?.languageCode ?? 'system');
    if (mounted) state = locale;
  }

  static Locale? _fromCode(String? code) => switch (code) {
        'pt' => const Locale('pt'),
        'en' => const Locale('en'),
        'es' => const Locale('es'),
        _ => null,
      };
}

final localeProvider = StateNotifierProvider<LocaleController, Locale?>(
  (ref) {
    final controller = LocaleController(DeviceLocalePreferenceStore());
    controller.load();
    return controller;
  },
);
