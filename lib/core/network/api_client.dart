import 'package:dio/dio.dart';
import 'token_storage.dart';

/// URL base do gateway. Em dev local: Android emulator usa 10.0.2.2 (não localhost),
/// iOS simulator/desktop usa localhost. Sobrescreva com:
///   flutter run --dart-define=API_BASE_URL=http://SEU_IP:3000
const _defaultBaseUrl = 'http://10.0.2.2:3000';

class ApiClient {
  ApiClient(this._tokenStorage, {void Function()? onUnauthorized})
      : _dio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _tokenStorage.clear();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;
}
