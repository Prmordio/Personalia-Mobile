import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/providers.dart';
import '../data/auth_api.dart';
import 'auth_controller.dart' show authApiProvider;

enum ForgotPasswordStep { email, code }

const _minPasswordLength = 8;
const _genericError = 'Não foi possível concluir. Tente novamente.';

class ForgotPasswordState {
  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.email = '',
    this.loading = false,
    this.error,
    this.info,
  });

  final ForgotPasswordStep step;
  final String email;
  final bool loading;
  final String? error;
  final String? info;

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    String? email,
    bool? loading,
    String? error,
    String? info,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      email: email ?? this.email,
      loading: loading ?? this.loading,
      error: error,
      info: info,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._authApi, this._tokenStorage, this._refresh) : super(const ForgotPasswordState());

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final ValueNotifier<int> _refresh;

  Future<void> requestCode(String email) async {
    if (!email.contains('@')) {
      state = state.copyWith(error: 'Informe um email válido.');
      return;
    }
    state = state.copyWith(loading: true);
    try {
      await _authApi.requestPasswordReset(email);
      state = state.copyWith(
        step: ForgotPasswordStep.code,
        email: email,
        loading: false,
        info: 'Se houver uma conta com $email, enviamos um código de 6 dígitos. Confira também o spam.',
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e));
    }
  }

  /// Redefine a senha e já entra no app com ela — o redirect do go_router leva para a Home.
  Future<void> resetPassword(String code, String password) async {
    if (code.length != 6) {
      state = state.copyWith(error: 'O código tem 6 dígitos.', info: state.info);
      return;
    }
    if (password.length < _minPasswordLength) {
      state = state.copyWith(error: 'A senha deve ter pelo menos $_minPasswordLength caracteres.', info: state.info);
      return;
    }
    state = state.copyWith(loading: true, info: state.info);
    try {
      await _authApi.resetPassword(state.email, code, password);
      final token = await _authApi.loginWithPassword(state.email, password);
      await _tokenStorage.save(token);
      _refresh.value++;
      state = state.copyWith(loading: false);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e), info: state.info);
    }
  }

  /// Volta para o passo do email (ex.: digitou o email errado ou quer um novo código).
  void restart() {
    state = ForgotPasswordState(email: state.email);
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    return message is String ? message : _genericError;
  }
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
  );
});
