import 'package:local_auth/local_auth.dart';

/// Prompt de biometria do sistema (digital / Face ID). Só confirma que é o dono do aparelho —
/// quem autentica no backend é a credencial guardada em [BiometricCredentialStorage].
class BiometricAuth {
  BiometricAuth([LocalAuthentication? localAuth]) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  Future<bool> isAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// false se o usuário cancelar ou a biometria falhar.
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(localizedReason: reason, biometricOnly: true);
    } on LocalAuthException {
      return false;
    }
  }
}
