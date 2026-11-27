import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/telemetry/app_telemetry.dart';

/// Estado da permissão "Atividades ao Vivo" (iOS 17+) que mostra o cronômetro
/// na tela de bloqueio e na Dynamic Island.
enum LiveActivityStatus { enabled, disabled, unsupported }

/// Porta para a plataforma: o nativo responde no canal `personalia/workout_live`.
abstract interface class LiveActivityPermissionGateway {
  Future<LiveActivityStatus> status();
  Future<void> openSettings();
}

class MethodChannelLiveActivityPermissionGateway
    implements LiveActivityPermissionGateway {
  const MethodChannelLiveActivityPermissionGateway();

  static const _channel = MethodChannel('personalia/workout_live');

  @override
  Future<LiveActivityStatus> status() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return LiveActivityStatus.unsupported;
    }
    try {
      final raw = await _channel.invokeMethod<String>('liveActivitiesStatus');
      return switch (raw) {
        'enabled' => LiveActivityStatus.enabled,
        'disabled' => LiveActivityStatus.disabled,
        _ => LiveActivityStatus.unsupported,
      };
    } on MissingPluginException {
      return LiveActivityStatus.unsupported;
    } on PlatformException {
      return LiveActivityStatus.unsupported;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<bool>('openSettings');
    } on MissingPluginException {
      // Sem ponte nativa (ex.: testes): nada a abrir.
    } on PlatformException catch (error) {
      debugPrint('Live activity settings: $error');
    }
  }
}

/// Persistência do "Não mostrar de novo".
abstract interface class LiveActivityHintStore {
  Future<bool> isDismissed();
  Future<void> dismiss();
}

class SecureLiveActivityHintStore implements LiveActivityHintStore {
  const SecureLiveActivityHintStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'live_activity_hint_dismissed';

  @override
  Future<bool> isDismissed() async =>
      (await _storage.read(key: _key).catchError((_) => null)) == 'true';

  @override
  Future<void> dismiss() => _storage.write(key: _key, value: 'true');
}

/// `true` quando o aviso deve aparecer: permissão desligada e o usuário não
/// dispensou. Rechecado ao voltar para o app (o usuário pode ter ativado nos Ajustes).
class LiveActivityHintController extends StateNotifier<bool> {
  LiveActivityHintController({
    required this._gateway,
    required this._store,
    void Function(String name, Map<String, Object?> params)? track,
  }) : _track = track ?? AppTelemetry.instance.event,
       super(false);

  final LiveActivityPermissionGateway _gateway;
  final LiveActivityHintStore _store;
  final void Function(String name, Map<String, Object?> params) _track;
  bool _reportedDisabled = false;

  Future<void> refresh() async {
    final status = await _gateway.status();
    if (status == LiveActivityStatus.disabled && !_reportedDisabled) {
      // Uma vez por sessão do app: mede quantos usuários estão com a permissão desligada.
      _reportedDisabled = true;
      _track('live_activity_disabled', const {});
    }
    final visible =
        status == LiveActivityStatus.disabled && !await _store.isDismissed();
    if (mounted) state = visible;
  }

  Future<void> openSettings() async {
    _track('live_activity_hint_action', const {'action': 'open_settings'});
    await _gateway.openSettings();
  }

  Future<void> dismiss() async {
    _track('live_activity_hint_action', const {'action': 'dismiss'});
    if (mounted) state = false;
    await _store.dismiss();
  }
}

final liveActivityPermissionGatewayProvider =
    Provider<LiveActivityPermissionGateway>(
      (ref) => const MethodChannelLiveActivityPermissionGateway(),
    );

final liveActivityHintStoreProvider = Provider<LiveActivityHintStore>(
  (ref) => const SecureLiveActivityHintStore(),
);

final liveActivityHintProvider =
    StateNotifierProvider<LiveActivityHintController, bool>(
      (ref) => LiveActivityHintController(
        gateway: ref.watch(liveActivityPermissionGatewayProvider),
        store: ref.watch(liveActivityHintStoreProvider),
      ),
    );
