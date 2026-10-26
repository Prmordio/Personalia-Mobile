import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  // --- Cadastro por email ---

  /// Envia o código de confirmação para o email. Devolve o id da sessão de cadastro.
  /// 409 = email já tem conta; 429 = pediu outro código cedo demais.
  Future<String> startSignup(String email) async {
    final response = await _dio.post('/auth/signup/start', data: {'email': email});
    return response.data['sessionId'] as String;
  }

  /// Confirma o código do email. Devolve `true` quando o email é de uma conta do WhatsApp: o
  /// telefone dela passa a ser obrigatório, para o cadastro trazer o histórico.
  Future<bool> verifySignupCode(String sessionId, String code) async {
    final response = await _dio.post('/auth/signup/verify', data: {'sessionId': sessionId, 'code': code});
    return response.data['linkAccount'] == true;
  }

  /// Envia o SMS que confirma o telefone, ainda dentro do cadastro (antes de a conta existir).
  /// 400 = telefone inválido ou, na conta do WhatsApp, diferente do número dela.
  Future<void> requestSignupPhoneCode(String sessionId, String phone) async {
    await _dio.post('/auth/signup/phone', data: {'sessionId': sessionId, 'phone': phone});
  }

  Future<void> verifySignupPhone(String sessionId, String code) async {
    await _dio.post('/auth/signup/phone-verify', data: {'sessionId': sessionId, 'code': code});
  }

  /// Cria a conta (ou assume a conta do WhatsApp, com email e telefone confirmados) já com a
  /// senha. Retorna o JWT.
  Future<String> completeSignup(String sessionId, String password) async {
    final response = await _dio.post(
      '/auth/signup/complete',
      data: {'sessionId': sessionId, 'password': password},
    );
    return response.data['token'] as String;
  }

  /// Login por email+senha. Retorna o JWT.
  Future<String> loginWithPassword(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return response.data['token'] as String;
  }

  /// "Esqueci minha senha": o backend envia um código de 6 dígitos para o email.
  /// Responde igual exista ou não conta com esse email.
  Future<void> requestPasswordReset(String email) async {
    await _dio.post('/auth/password/forgot', data: {'email': email});
  }

  Future<void> resetPassword(String email, String code, String password) async {
    await _dio.post('/auth/password/reset', data: {'email': email, 'code': code, 'password': password});
  }

  // --- Primeiro acesso / redefinição de senha (conta do WhatsApp: valida email + telefone) ---

  /// Responde igual exista ou não a conta; devolve o id da sessão e qual tela mostrar primeiro.
  Future<({String sessionId, String nextStep})> startAppAccess(String phone, String email) async {
    final response = await _dio.post('/auth/app-access/start', data: {'phone': phone, 'email': email});
    return (
      sessionId: response.data['sessionId'] as String,
      nextStep: (response.data['nextStep'] as String?) ?? 'email_code',
    );
  }

  /// [factor] é 'email' ou 'phone'. Devolve o próximo passo:
  /// 'phone_code' | 'email_code' | 'confirm_email' | 'password'.
  Future<String> verifyAppAccessCode(String sessionId, String factor, String code) async {
    final response = await _dio.post(
      '/auth/app-access/verify',
      data: {'sessionId': sessionId, 'factor': factor, 'code': code},
    );
    return response.data['next'] as String;
  }

  /// "Não recebi": se a janela do WhatsApp estiver aberta, o código sai na hora.
  Future<void> requestAppAccessWhatsAppCode(String sessionId) async {
    await _dio.post('/auth/app-access/whatsapp', data: {'sessionId': sessionId});
  }

  /// Confirmar/corrigir o email (só depois do telefone validado) — envia um código para ele.
  Future<void> changeAppAccessEmail(String sessionId, String email) async {
    await _dio.post('/auth/app-access/email', data: {'sessionId': sessionId, 'email': email});
  }

  // --- Login por biometria ---

  /// Registra este aparelho (exige estar logado). Retorna (credentialId, token).
  Future<(String, String)> enrollBiometric(String deviceName) async {
    final response = await _dio.post('/auth/biometric/enroll', data: {'deviceName': deviceName});
    return (response.data['credentialId'] as String, response.data['token'] as String);
  }

  /// Troca a credencial do aparelho por um JWT.
  Future<String> loginWithBiometric(String credentialId, String token) async {
    final response = await _dio.post(
      '/auth/biometric/login',
      data: {'credentialId': credentialId, 'token': token},
    );
    return response.data['token'] as String;
  }

  Future<void> revokeBiometric(String credentialId) async {
    await _dio.post('/auth/biometric/revoke', data: {'credentialId': credentialId});
  }

  /// Retorna o JWT.
  Future<String> completeAppAccess(String sessionId, String password) async {
    final response = await _dio.post(
      '/auth/app-access/complete',
      data: {'sessionId': sessionId, 'password': password},
    );
    return response.data['token'] as String;
  }
}
