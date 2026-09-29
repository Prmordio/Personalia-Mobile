import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/features/auth/data/auth_api.dart';
import 'package:personalia_app/features/auth/state/forgot_password_controller.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());

  final calls = <String>[];
  DioException? resetError;

  @override
  Future<void> requestPasswordReset(String email) async => calls.add('forgot:$email');

  @override
  Future<void> resetPassword(String email, String code, String password) async {
    calls.add('reset:$email:$code:$password');
    if (resetError != null) throw resetError!;
  }

  @override
  Future<String> loginWithPassword(String email, String password) async {
    calls.add('login:$email:$password');
    return 'jwt-token';
  }
}

class _FakeTokenStorage extends TokenStorage {
  String? saved;

  @override
  Future<void> save(String token) async => saved = token;
}

void main() {
  late _FakeAuthApi api;
  late _FakeTokenStorage storage;
  late ValueNotifier<int> refresh;
  late ForgotPasswordController controller;

  setUp(() {
    api = _FakeAuthApi();
    storage = _FakeTokenStorage();
    refresh = ValueNotifier(0);
    controller = ForgotPasswordController(api, storage, refresh);
  });

  test('should_return_error_when_email_is_invalid', () async {
    await controller.requestCode('sem-arroba');

    expect(controller.state.error, isNotNull);
    expect(controller.state.step, ForgotPasswordStep.email);
    expect(api.calls, isEmpty);
  });

  test('should_move_to_code_step_after_requesting_the_code', () async {
    await controller.requestCode('joao@example.com');

    expect(api.calls, ['forgot:joao@example.com']);
    expect(controller.state.step, ForgotPasswordStep.code);
    expect(controller.state.email, 'joao@example.com');
  });

  test('should_reject_short_password_without_calling_the_api', () async {
    await controller.requestCode('joao@example.com');
    await controller.resetPassword('123456', 'curta');

    expect(controller.state.error, contains('8 caracteres'));
    expect(api.calls, ['forgot:joao@example.com']);
  });

  test('should_reset_and_log_in_with_the_new_password', () async {
    await controller.requestCode('joao@example.com');
    await controller.resetPassword('123456', 'nova-senha-forte');

    expect(api.calls, [
      'forgot:joao@example.com',
      'reset:joao@example.com:123456:nova-senha-forte',
      'login:joao@example.com:nova-senha-forte',
    ]);
    expect(storage.saved, 'jwt-token');
    expect(refresh.value, 1);
  });

  test('should_show_backend_message_when_code_is_invalid', () async {
    api.resetError = DioException(
      requestOptions: RequestOptions(path: '/auth/password/reset'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/password/reset'),
        statusCode: 401,
        data: {'message': 'Código inválido ou expirado'},
      ),
    );
    await controller.requestCode('joao@example.com');
    await controller.resetPassword('000000', 'nova-senha-forte');

    expect(controller.state.error, 'Código inválido ou expirado');
    expect(controller.state.step, ForgotPasswordStep.code);
    expect(storage.saved, isNull);
  });
}
