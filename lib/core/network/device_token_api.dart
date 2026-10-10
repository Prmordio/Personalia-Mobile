import 'package:dio/dio.dart';

class DeviceTokenApi {
  DeviceTokenApi(this._dio);
  final Dio _dio;

  Future<void> register(String token, String platform) async {
    await _dio.post(
      '/app/device-token',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregister(String token) async {
    await _dio.delete(
      '/app/device-token',
      data: {'token': token},
    );
  }
}
