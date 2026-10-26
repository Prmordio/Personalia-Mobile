import 'package:dio/dio.dart';
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
}
