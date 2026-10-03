import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/providers.dart';
import '../data/auth_api.dart';
import 'auth_controller.dart' show authApiProvider;
import 'biometric_login_service.dart' show biometricOfferPendingProvider;

/// Telas do primeiro acesso / redefinição de senha (conta do WhatsApp):
/// start → emailCode ⇄ phoneCode → [confirmEmail → emailCode] → password.
enum AppAccessStep { start, emailCode, phoneCode, confirmEmail, password }

const _minPasswordLength = 8;
const _genericError = 'Não foi possível concluir. Tente novamente.';

class AppAccessState {
  const AppAccessState({
    this.step = AppAccessStep.start,
    this.sessionId,
    this.email = '',
    this.emailVerified = false,
    this.phoneVerified = false,
    this.loading = false,
    this.error,
    this.info,
  });

  final AppAccessStep step;
  final String? sessionId;
  final String email;
  final bool emailVerified;
  final bool phoneVerified;
  final bool loading;
  final String? error;
  final String? info;

  AppAccessState copyWith({
    AppAccessStep? step,
    String? sessionId,
    String? email,
    bool? emailVerified,
    bool? phoneVerified,
    bool? loading,
    String? error,
    String? info,
  }) {
    return AppAccessState(
      step: step ?? this.step,
      sessionId: sessionId ?? this.sessionId,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      loading: loading ?? this.loading,
      error: error,
      info: info,
    );
  }
}

class AppAccessController extends StateNotifier<AppAccessState> {
  AppAccessController(this._authApi, this._tokenStorage, this._refresh, {this.onLoggedIn})
      : super(const AppAccessState());

  /// Chamado depois de salvar o token (a Home oferece ativar a biometria).
  final void Function()? onLoggedIn;

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final ValueNotifier<int> _refresh;

  Future<void> start(String phone, String email) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      state = state.copyWith(error: 'Informe o telefone com DDD.');
      return;
    }
    if (!email.contains('@')) {
      state = state.copyWith(error: 'Informe um email válido.');
      return;
    }
    await _run(() async {
      final result = await _authApi.startAppAccess(digits, email);
      final step = result.nextStep == 'phone_code' ? AppAccessStep.phoneCode : AppAccessStep.emailCode;
      state = state.copyWith(
        step: step,
        sessionId: result.sessionId,
        email: email,
        loading: false,
        // Mesma mensagem exista ou não o cadastro — o backend não confirma nem nega.
        info: 'Se houver cadastro com esses dados, enviamos um código para o email e/ou WhatsApp cadastrados.',
      );
    });
  }

  Future<void> verifyCode(String code) async {
    if (code.length != 6) {
      state = state.copyWith(error: 'O código tem 6 dígitos.', info: state.info);
      return;
    }
    final factor = state.step == AppAccessStep.phoneCode ? 'phone' : 'email';
    await _run(() async {
      final next = await _authApi.verifyAppAccessCode(state.sessionId!, factor, code);
      final verified = state.copyWith(
        emailVerified: factor == 'email' ? true : null,
        phoneVerified: factor == 'phone' ? true : null,
        loading: false,
      );
      state = switch (next) {
        'password' => verified.copyWith(step: AppAccessStep.password),
        'phone_code' => verified.copyWith(
            step: AppAccessStep.phoneCode,
            info: 'Email confirmado ✅ Agora confirme seu número pelo WhatsApp.',
          ),
        'email_code' => verified.copyWith(
            step: AppAccessStep.emailCode,
            info: 'Número confirmado ✅ Digite o código que enviamos para ${state.email}.',
          ),
        _ => verified.copyWith(step: AppAccessStep.confirmEmail),
      };
    });
  }

  /// "Não recebi o email / email errado": vai para a confirmação pelo WhatsApp.
  Future<void> useWhatsApp() async {
    await _run(() async {
      await _authApi.requestAppAccessWhatsAppCode(state.sessionId!);
      state = state.copyWith(step: AppAccessStep.phoneCode, loading: false);
    });
  }

  /// Com o telefone já validado: volta para confirmar/corrigir o email.
  void editEmail() {
    state = state.copyWith(step: AppAccessStep.confirmEmail);
  }

  Future<void> confirmEmail(String email) async {
    if (!email.contains('@')) {
      state = state.copyWith(error: 'Informe um email válido.');
      return;
    }
    await _run(() async {
      await _authApi.changeAppAccessEmail(state.sessionId!, email);
      state = state.copyWith(
        step: AppAccessStep.emailCode,
        email: email,
        loading: false,
        info: 'Enviamos um código para $email.',
      );
    });
  }

  /// Cria a senha e já entra no app — o redirect do go_router leva para a Home/onboarding.
  Future<void> complete(String password, String confirmation) async {
    if (password.length < _minPasswordLength) {
      state = state.copyWith(error: 'A senha deve ter pelo menos $_minPasswordLength caracteres.');
      return;
    }
    if (password != confirmation) {
      state = state.copyWith(error: 'As senhas não conferem.');
      return;
    }
    await _run(() async {
      final token = await _authApi.completeAppAccess(state.sessionId!, password);
      await _tokenStorage.save(token);
      onLoggedIn?.call();
      _refresh.value++;
      state = state.copyWith(loading: false);
    });
  }

  /// Recomeça do zero (sessão expirada, dados digitados errado).
  void restart() {
    state = const AppAccessState();
  }

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(loading: true, info: state.info);
    try {
      await action();
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e), info: state.info);
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    return message is String ? message : _genericError;
  }
}

final appAccessControllerProvider =
    StateNotifierProvider.autoDispose<AppAccessController, AppAccessState>((ref) {
  return AppAccessController(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
    onLoggedIn: () => ref.read(biometricOfferPendingProvider.notifier).state = true,
  );
});
