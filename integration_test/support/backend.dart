import 'package:dio/dio.dart';
import 'mailbox.dart';
import 'e2e_env.dart';

/// Acesso direto ao gateway para conferir, depois de cada fluxo na UI, o que ficou gravado
/// no backend (a UI pode mostrar sucesso a partir do cache local).
class Backend {
  Backend() : _dio = Dio(BaseOptions(baseUrl: E2eEnv.apiBaseUrl));
  final Dio _dio;

  Future<String> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return response.data['token'] as String;
  }

  Future<dynamic> get(String path, String token) async {
    final response = await _dio.get(path, options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<dynamic> put(String path, String token, Map<String, dynamic> body) async {
    final response = await _dio.put(path, data: body, options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  /// Conta nova pelo cadastro por email (código lido no Mailpit) com o onboarding completo pela
  /// API — o login cai direto na home. Mesmo caminho do seed_user.py, sem treino nem assinatura.
  Future<void> createOnboardedAccount(String email, String password, Mailbox mailbox) async {
    final start = await _dio.post('/auth/signup/start', data: {'email': email});
    final sessionId = start.data['sessionId'] as String;
    final code = await mailbox.waitForCode(email);
    await _dio.post('/auth/signup/verify', data: {'sessionId': sessionId, 'code': code});
    final complete = await _dio.post('/auth/signup/complete', data: {'sessionId': sessionId, 'password': password});
    final token = complete.data['token'] as String;

    await put('/app/onboarding/profile', token, {
      'name': 'Usuário E2E', 'gender': 'Masculino', 'birthDate': '15/03/1990',
      'weight': 80, 'height': 178, 'email': email,
    });
    await put('/app/onboarding/disclaimer', token, {'accepted': true, 'cpf': '52998224725'});
    await put('/app/onboarding/anamnesis', token, {
      'mainGoal': 'ganho_massa', 'hasDiseases': false, 'hasPhysicalLimitations': false,
      'physicalActivityLevel': 'moderado',
    });
    await put('/app/onboarding/training-preferences', token, {
      'minTrainingDuration': 30, 'maxTrainingDuration': 60, 'trainingDaysPerWeek': 3,
      'wantsCardio': false, 'trainingFocus': 'corpo_todo',
    });
  }
}
