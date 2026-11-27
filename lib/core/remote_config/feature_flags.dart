import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_remote_config.dart';

/// Flags remotas (Remote Config). Todo default é o comportamento atual: sem rede ou
/// sem a chave publicada, nada muda para o usuário.
class FeatureFlags {
  const FeatureFlags({
    this.assistantEnabled = true,
    this.executionAnalysisEnabled = true,
    this.maintenanceMessage = '',
  });

  factory FeatureFlags.from(RemoteConfigValues config) => FeatureFlags(
    assistantEnabled: parseFlag(
      config.getString(RemoteConfigKeys.assistantEnabled),
    ),
    executionAnalysisEnabled: parseFlag(
      config.getString(RemoteConfigKeys.executionAnalysisEnabled),
    ),
    maintenanceMessage: config.getString(RemoteConfigKeys.maintenanceMessage),
  );

  final bool assistantEnabled;
  final bool executionAnalysisEnabled;
  final String maintenanceMessage;

  /// Texto do aviso no idioma do app, ou null quando não há aviso.
  String? maintenanceFor(String languageCode) =>
      maintenanceText(maintenanceMessage, languageCode);
}

/// Só `false` explícito desliga: valor vazio/inválido mantém a feature ligada.
bool parseFlag(String raw) => raw.trim().toLowerCase() != 'false';

/// Aceita texto puro ou JSON `{"pt": "...", "en": "...", "es": "..."}` (fallback: pt).
String? maintenanceText(String raw, String languageCode) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  if (!text.startsWith('{')) return text;
  try {
    final map = jsonDecode(text);
    if (map is! Map) return null;
    final value = map[languageCode] ?? map['pt'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  } catch (_) {
    return null;
  }
}

final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => ref
      .watch(remoteConfigProvider)
      .maybeWhen(data: FeatureFlags.from, orElse: () => const FeatureFlags()),
);
