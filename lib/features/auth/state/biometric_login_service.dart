import '../../../core/telemetry/app_telemetry.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/providers.dart';
import '../../../core/security/biometric_auth.dart';
import '../../../core/security/biometric_credential_storage.dart';
import '../data/auth_api.dart';
import 'auth_controller.dart' show authApiProvider;

enum BiometricLoginResult { success, cancelled, notEnabled, invalidCredential, failed }

/// Ativar, usar e desativar o login por biometria neste aparelho.
class BiometricLoginService {
  BiometricLoginService(this._authApi, this._biometricAuth, this._credentialStorage, this._tokenStorage, this._refresh);

  final AuthApi _authApi;
  final BiometricAuth _biometricAuth;
  final BiometricCredentialStorage _credentialStorage;
  final TokenStorage _tokenStorage;
  final ValueNotifier<int> _refresh;

  Future<bool> isEnabled() async => await _credentialStorage.read() != null;

  /// Aparelho tem biometria cadastrada e ela ainda não está ativa no app.
  Future<bool> canEnable() async => !await isEnabled() && await _biometricAuth.isAvailable();

  /// Exige estar logado. Confirma a digital/rosto antes de registrar o aparelho.
  Future<bool> enable() async {
    if (!await _biometricAuth.authenticate('Confirme para ativar o login por biometria')) return false;
    try {
      final (credentialId, token) = await _authApi.enrollBiometric(Platform.operatingSystem);
      await _credentialStorage.save(BiometricCredential(credentialId: credentialId, token: token));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricLoginResult> login() async {
    final credential = await _credentialStorage.read();
    if (credential == null) return BiometricLoginResult.notEnabled;
    if (!await _biometricAuth.authenticate('Entre no PersonalIA')) return BiometricLoginResult.cancelled;

    try {
      final jwt = await _authApi.loginWithBiometric(credential.credentialId, credential.token);
      await _tokenStorage.save(jwt);
      AppTelemetry.instance.event('login');
      _refresh.value++;
      return BiometricLoginResult.success;
    } on DioException catch (e) {
      // Revogada (troca de senha, desativada) ou expirada por inatividade: só a senha resolve.
      if (e.response?.statusCode == 401) {
        await _credentialStorage.clear();
        return BiometricLoginResult.invalidCredential;
      }
      return BiometricLoginResult.failed;
    }
  }

  /// Desativa neste aparelho (revoga no backend se estiver logado; apaga localmente sempre).
  Future<void> disable() async {
    final credential = await _credentialStorage.read();
    if (credential == null) return;
    try {
      await _authApi.revokeBiometric(credential.credentialId);
    } catch (_) {
      // Sem sessão/rede: a credencial local some de qualquer jeito; a do backend expira sozinha.
    }
    await _credentialStorage.clear();
  }
}

final biometricLoginServiceProvider = Provider<BiometricLoginService>((ref) {
  return BiometricLoginService(
    ref.watch(authApiProvider),
    BiometricAuth(),
    BiometricCredentialStorage(),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
  );
});

/// true logo depois de um login com senha — a Home oferece ativar a biometria uma vez.
final biometricOfferPendingProvider = StateProvider<bool>((ref) => false);
