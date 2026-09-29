import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<List<String>> getChannels(String phoneNumber) async {
    final response = await _dio.get('/auth/otp/channels', queryParameters: {'phoneNumber': phoneNumber});
    return List<String>.from(response.data['channels'] as List);
  }

  Future<void> requestOtp(String phoneNumber, String channel) async {
    await _dio.post('/auth/otp/request', data: {'phoneNumber': phoneNumber, 'channel': channel});
  }

  /// Retorna o JWT.
  Future<String> verifyOtp(String phoneNumber, String code) async {
    final response = await _dio.post('/auth/otp/verify', data: {'phoneNumber': phoneNumber, 'code': code});
    return response.data['token'] as String;
  }

  /// Login alternativo por email+senha (pra quem já definiu senha no onboarding), sem OTP.
  /// Retorna o mesmo formato de JWT que o login por OTP.
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

  /// Responde igual exista ou não a conta; devolve o id da sessão de acesso.
  Future<String> startAppAccess(String phone, String email) async {
    final response = await _dio.post('/auth/app-access/start', data: {'phone': phone, 'email': email});
    return response.data['sessionId'] as String;
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
