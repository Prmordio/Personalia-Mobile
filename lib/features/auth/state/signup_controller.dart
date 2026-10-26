import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/providers.dart';
import '../../../core/telemetry/app_telemetry.dart';
import '../data/auth_api.dart';
import 'auth_controller.dart' show authApiProvider;

/// Cadastro no app: email → código por email → senha (+ telefone) → [código SMS] → conta criada.
/// O telefone é confirmado por SMS antes de a conta existir. Ele é opcional, exceto quando o
/// email é de uma conta do WhatsApp: aí precisa ser o número dela, e o cadastro entra nessa conta
/// (com o histórico) em vez de criar outra.
enum SignupStep { email, code, password, phoneCode }

const _minPasswordLength = 8;
const _genericError = 'genericError';
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class SignupState {
  const SignupState({
    this.step = SignupStep.email,
    this.email = '',
    this.phone = '',
    this.sessionId,
    this.linkAccount = false,
    this.loading = false,
    this.emailTaken = false,
    this.error,
    this.info,
  });

  final SignupStep step;
  final String email;

  /// Telefone informado (só dígitos), aguardando a confirmação por SMS.
  final String phone;
  final String? sessionId;

  /// O email é de uma conta do WhatsApp: telefone obrigatório, sem "pular".
  final bool linkAccount;
  final bool loading;

  /// O email já tem conta — a tela oferece ir para o login em vez de seguir no cadastro.
  final bool emailTaken;
  final String? error;
  final String? info;

  SignupState copyWith({
    SignupStep? step,
    String? email,
    String? phone,
    String? sessionId,
    bool? linkAccount,
    bool? loading,
    bool? emailTaken,
    String? error,
    String? info,
  }) {
    return SignupState(
      step: step ?? this.step,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      sessionId: sessionId ?? this.sessionId,
      linkAccount: linkAccount ?? this.linkAccount,
      loading: loading ?? this.loading,
      emailTaken: emailTaken ?? false,
      error: error,
      info: info,
    );
  }
}

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._authApi, this._tokenStorage, this._refresh) : super(const SignupState());

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final ValueNotifier<int> _refresh;

  /// Senha já validada no passo da senha, guardada até o SMS ser confirmado: a conta só é criada
  /// (ou vinculada) no fim, para não ficar conta pela metade se a pessoa desistir no SMS.
  String? _password;

  Future<void> requestCode(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      state = state.copyWith(error: 'errAppAccessEmail');
      return;
    }
    state = state.copyWith(loading: true, email: email);
    try {
      final sessionId = await _authApi.startSignup(email);
      state = state.copyWith(
        step: SignupStep.code,
        sessionId: sessionId,
        loading: false,
        info: 'appAccessInfoCodeSentTo:$email',
      );
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        emailTaken: e.response?.statusCode == 409,
        error: _messageFrom(e),
      );
    }
  }

  /// A pessoa está corrigindo o email: some o "já tem conta" e o botão de enviar volta.
  void editEmail() {
    if (state.emailTaken || state.error != null) {
      state = state.copyWith();
    }
  }

  /// "Reenviar código": abre outra sessão para o mesmo email (o backend aplica o cooldown).
  Future<void> resendCode() async {
    state = state.copyWith(loading: true, info: state.info);
    try {
      final sessionId = await _authApi.startSignup(state.email);
      state = state.copyWith(sessionId: sessionId, loading: false, info: 'infoAuthCodeResent');
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e), info: state.info);
    }
  }

  Future<void> verifyCode(String code) async {
    if (code.length != 6) {
      state = state.copyWith(error: 'errAuthCodeLength', info: state.info);
      return;
    }
    state = state.copyWith(loading: true, info: state.info);
    try {
      final linkAccount = await _authApi.verifySignupCode(state.sessionId!, code);
      state = state.copyWith(step: SignupStep.password, linkAccount: linkAccount, loading: false);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e), info: state.info);
    }
  }

  /// Sem telefone, cria a conta e entra; com telefone, envia o SMS e vai para o código.
  Future<void> createAccount({required String password, required String confirmation, String phone = ''}) async {
    if (password.length < _minPasswordLength) {
      state = state.copyWith(error: 'errAuthPasswordTooShort');
      return;
    }
    if (password != confirmation) {
      state = state.copyWith(error: 'errPasswordMismatch');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty && state.linkAccount) {
      state = state.copyWith(error: 'errSignupPhoneRequired');
      return;
    }
    if (digits.isNotEmpty && (digits.length < 10 || digits.length > 15)) {
      state = state.copyWith(error: 'errSignupPhoneInvalid');
      return;
    }
    _password = password;
    if (digits.isEmpty) {
      state = state.copyWith(loading: true);
      await _complete();
      return;
    }
    state = state.copyWith(step: SignupStep.phoneCode, phone: digits);
    await sendPhoneCode();
  }

  /// Envia (ou reenvia) o SMS. Telefone recusado (400 — ex.: não é o número da conta do
  /// WhatsApp) volta para o passo da senha para corrigir; outras falhas ficam aqui para tentar
  /// de novo (ou pular, se o telefone for opcional).
  Future<void> sendPhoneCode() async {
    state = state.copyWith(loading: true);
    try {
      await _authApi.requestSignupPhoneCode(state.sessionId!, state.phone);
      state = state.copyWith(loading: false, info: 'signupPhoneCodeSentTo:${state.phone}');
    } on DioException catch (e) {
      final rejected = e.response?.statusCode == 400;
      state = state.copyWith(
        step: rejected ? SignupStep.password : null,
        loading: false,
        error: _messageFrom(e),
      );
    }
  }

  Future<void> verifyPhoneCode(String code) async {
    if (code.length != 6) {
      state = state.copyWith(error: 'errAuthCodeLength', info: state.info);
      return;
    }
    state = state.copyWith(loading: true, info: state.info);
    try {
      await _authApi.verifySignupPhone(state.sessionId!, code);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e), info: state.info);
      return;
    }
    await _complete();
  }

  /// Segue sem o telefone (ele não é salvo). Na conta do WhatsApp o telefone é obrigatório.
  Future<void> skipPhone() async {
    if (state.linkAccount) return;
    state = state.copyWith(loading: true);
    await _complete();
  }

  /// Volta do SMS para o passo da senha (trocar o número). A conta ainda não existe.
  void backToPassword() {
    state = state.copyWith(step: SignupStep.password);
  }

  /// Volta para o passo do email (digitou errado ou não recebeu o código).
  void restart() {
    state = SignupState(email: state.email);
  }

  /// Cria (ou vincula) a conta e entra no app — o redirect do go_router leva para o onboarding
  /// ou, na conta do WhatsApp já configurada, direto para a home.
  Future<void> _complete() async {
    try {
      final token = await _authApi.completeSignup(state.sessionId!, _password!);
      await _tokenStorage.save(token);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _messageFrom(e));
      return;
    }
    AppTelemetry.instance.event(state.linkAccount ? 'sign_up_whatsapp_linked' : 'sign_up');
    _refresh.value++;
    state = state.copyWith(loading: false);
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    return message is String ? message : _genericError;
  }
}

final signupControllerProvider = StateNotifierProvider.autoDispose<SignupController, SignupState>((ref) {
  return SignupController(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
  );
});
