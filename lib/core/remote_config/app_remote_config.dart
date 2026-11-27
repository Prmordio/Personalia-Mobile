import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Chaves do Remote Config usadas pelo app (todas com default seguro: sem rede ou sem a
/// chave publicada, o app se comporta como antes).
abstract final class RemoteConfigKeys {
  /// SHA-256 (hex) dos emails com acesso ilimitado (ex.: conta demo da revisão das lojas).
  static const unlimitedAccessEmailHashes = 'unlimited_access_email_hashes';

  /// Versão mínima suportada (ex.: `3.4.0`). Abaixo dela o app bloqueia e pede para atualizar.
  static const minAppVersion = 'min_app_version';

  /// Versão recomendada. Abaixo dela o app sugere atualizar (uma vez por versão).
  static const recommendedAppVersion = 'recommended_app_version';

  /// Kill switch do chat do assistente (`false` esconde as entradas). Default ligado.
  static const assistantEnabled = 'assistant_enabled';

  /// Kill switch da análise de execução por vídeo. Default ligado.
  static const executionAnalysisEnabled = 'execution_analysis_enabled';

  /// Aviso de manutenção/instabilidade no topo do app. Vazio = sem aviso. Texto puro ou
  /// JSON por idioma: `{"pt":"...","en":"...","es":"..."}`.
  static const maintenanceMessage = 'maintenance_message';

  /// SHA-256 (hex) dos emails da equipe/testers: viram a user property
  /// `internal_tester=true` para filtrar a atividade interna do Analytics.
  static const internalTesterEmailHashes = 'internal_tester_email_hashes';

  static const defaults = <String, Object>{
    unlimitedAccessEmailHashes: '',
    minAppVersion: '',
    recommendedAppVersion: '',
    assistantEnabled: true,
    executionAnalysisEnabled: true,
    maintenanceMessage: '',
    internalTesterEmailHashes: '',
  };
}

/// Leitura dos valores do Remote Config (abstração para testes e para as features não
/// dependerem do SDK do Firebase).
abstract interface class RemoteConfigValues {
  String getString(String key);
}

class _FirebaseRemoteConfigValues implements RemoteConfigValues {
  _FirebaseRemoteConfigValues(this._config);
  final FirebaseRemoteConfig _config;

  @override
  String getString(String key) => _config.getString(key);
}

/// Carrega o Remote Config uma vez por sessão. Sem rede, vale o último valor ativado
/// (ou os defaults no primeiro uso).
Future<RemoteConfigValues> loadRemoteConfig() async {
  // O shell pode montar antes do startup terminar; initializeApp é idempotente.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  final config = FirebaseRemoteConfig.instance;
  await config.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  await config.setDefaults(RemoteConfigKeys.defaults);
  try {
    await config.fetchAndActivate();
  } catch (_) {
    // Sem rede, vale o último valor ativado.
  }
  return _FirebaseRemoteConfigValues(config);
}

final remoteConfigProvider = FutureProvider<RemoteConfigValues>((ref) => loadRemoteConfig());
