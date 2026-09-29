import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'auth_controller.dart' show authApiProvider;
import 'biometric_login_service.dart' show biometricOfferPendingProvider;

class PasswordLoginState {
  const PasswordLoginState({this.loading = false, this.error});

  final bool loading;
  final String? error;

  PasswordLoginState copyWith({bool? loading, String? error}) {
    return PasswordLoginState(loading: loading ?? this.loading, error: error);
  }
}

class PasswordLoginController extends StateNotifier<PasswordLoginState> {
  PasswordLoginController(this._authApi, this._tokenStorage, this._refresh, {this.onLoggedIn})
      : super(const PasswordLoginState());

  /// Chamado depois de salvar o token (a Home oferece ativar a biometria).
  final void Function()? onLoggedIn;

  final dynamic _authApi;
  final dynamic _tokenStorage;
  final dynamic _refresh;

  Future<bool> submit(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await _authApi.loginWithPassword(email, password);
      await _tokenStorage.save(token);
      onLoggedIn?.call();
      _refresh.value++;
      state = state.copyWith(loading: false);
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message'] as String?) : null;
      state = state.copyWith(loading: false, error: message ?? 'Não foi possível entrar. Tente novamente.');
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Não foi possível entrar. Tente novamente.');
      return false;
    }
  }
}

final passwordLoginControllerProvider = StateNotifierProvider<PasswordLoginController, PasswordLoginState>((ref) {
  return PasswordLoginController(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
    onLoggedIn: () => ref.read(biometricOfferPendingProvider.notifier).state = true,
  );
});
