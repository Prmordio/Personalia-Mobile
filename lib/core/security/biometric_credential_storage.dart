import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricCredential {
  const BiometricCredential({required this.credentialId, required this.token});
  final String credentialId;
  final String token;
}

/// Credencial de aparelho emitida pelo backend para o login por biometria. Fica no
/// armazenamento seguro do sistema (Keystore/Keychain) — o app nunca guarda a senha.
/// Separada do JWT: sair da conta não apaga a biometria (dá pra voltar com a digital).
class BiometricCredentialStorage {
  BiometricCredentialStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _idKey = 'biometric_credential_id';
  static const _tokenKey = 'biometric_credential_token';

  Future<BiometricCredential?> read() async {
    final id = await _storage.read(key: _idKey);
    final token = await _storage.read(key: _tokenKey);
    if (id == null || token == null) return null;
    return BiometricCredential(credentialId: id, token: token);
  }

  Future<void> save(BiometricCredential credential) async {
    await _storage.write(key: _idKey, value: credential.credentialId);
    await _storage.write(key: _tokenKey, value: credential.token);
  }

  Future<void> clear() async {
    await _storage.delete(key: _idKey);
    await _storage.delete(key: _tokenKey);
  }
}
