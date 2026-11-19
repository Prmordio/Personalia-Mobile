import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../remote_config/app_remote_config.dart';
import 'version_policy.dart';

/// Links das lojas (mesmos da landing page).
abstract final class StoreLinks {
  static const android = 'https://play.google.com/store/apps/details?id=com.personalia.personalia_app';
  static const ios = 'https://apps.apple.com/app/id6820336863';

  static String forPlatform(TargetPlatform platform) => platform == TargetPlatform.iOS ? ios : android;
}

class UpdateStatus {
  const UpdateStatus({required this.requirement, this.target});
  final UpdateRequirement requirement;

  /// Versão que motivou o aviso (para lembrar que o usuário já dispensou a recomendação).
  final AppVersion? target;

  static const none = UpdateStatus(requirement: UpdateRequirement.none);
}

/// Versão instalada do app.
final installedVersionProvider = FutureProvider<AppVersion?>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion.tryParse(info.version);
});

/// Compara a versão instalada com `min_app_version` / `recommended_app_version` do Remote
/// Config. Qualquer falha (sem Firebase, sem rede) resulta em "sem exigência".
final updateStatusProvider = FutureProvider<UpdateStatus>((ref) async {
  try {
    final current = await ref.watch(installedVersionProvider.future);
    final config = await ref.watch(remoteConfigProvider.future);
    final minimum = AppVersion.tryParse(config.getString(RemoteConfigKeys.minAppVersion));
    final recommended = AppVersion.tryParse(config.getString(RemoteConfigKeys.recommendedAppVersion));
    final requirement = evaluateUpdate(current: current, minimum: minimum, recommended: recommended);
    return UpdateStatus(
      requirement: requirement,
      target: requirement == UpdateRequirement.required ? minimum : recommended,
    );
  } catch (error) {
    debugPrint('[Update] check skipped: ${error.runtimeType}');
    return UpdateStatus.none;
  }
});

/// Lembra qual versão recomendada o usuário já dispensou (pergunta de novo só numa nova).
abstract interface class DismissedUpdateStore {
  Future<String?> read();
  Future<void> write(String version);
}

class SecureDismissedUpdateStore implements DismissedUpdateStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'dismissed_recommended_update';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String version) => _storage.write(key: _key, value: version);
}

final dismissedUpdateStoreProvider = Provider<DismissedUpdateStore>((ref) => SecureDismissedUpdateStore());
