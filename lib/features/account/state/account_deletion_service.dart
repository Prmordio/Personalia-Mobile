import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/providers.dart';
import '../../../core/security/biometric_credential_storage.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/state/auth_controller.dart' show authApiProvider;

/// Exclusão da conta pelo próprio usuário (exigência da App Store).
///
/// Só limpa a sessão local depois que o backend confirma a exclusão: se a chamada falhar, o
/// usuário continua logado e pode tentar de novo. A credencial de biometria deste aparelho é
/// apagada junto — no backend ela já some em cascata com a conta.
class AccountDeletionService {
  AccountDeletionService(this._authApi, this._credentialStorage, this._tokenStorage, this._refresh);

  final AuthApi _authApi;
  final BiometricCredentialStorage _credentialStorage;
  final TokenStorage _tokenStorage;
  final ValueNotifier<int> _refresh;

  Future<void> deleteAccount() async {
    await _authApi.deleteAccount();
    await _credentialStorage.clear();
    await _tokenStorage.clear();
    // Mesmo sinal do logout: o go_router redireciona para a tela de entrada.
    _refresh.value++;
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    ref.watch(authApiProvider),
    BiometricCredentialStorage(),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
  );
});
