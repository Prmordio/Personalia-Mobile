import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/features/auth/data/auth_api.dart';
import 'package:personalia_app/features/auth/state/app_access_controller.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());

  final calls = <String>[];
  final nextSteps = <String>[];
  DioException? verifyError;

  @override
  Future<String> startAppAccess(String phone, String email) async {
    calls.add('start:$phone:$email');
    return 'session-1';
  }

  @override
  Future<String> verifyAppAccessCode(String sessionId, String factor, String code) async {
    calls.add('verify:$factor:$code');
    if (verifyError != null) throw verifyError!;
    return nextSteps.removeAt(0);
  }

  @override
  Future<void> requestAppAccessWhatsAppCode(String sessionId) async => calls.add('whatsapp');

  @override
  Future<void> changeAppAccessEmail(String sessionId, String email) async => calls.add('email:$email');

  @override
  Future<String> completeAppAccess(String sessionId, String password) async {
    calls.add('complete:$password');
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
  late AppAccessController controller;

  setUp(() {
    api = _FakeAuthApi();
    storage = _FakeTokenStorage();
    refresh = ValueNotifier(0);
    controller = AppAccessController(api, storage, refresh);
  });

  test('should_validate_phone_and_email_before_calling_the_api', () async {
    await controller.start('1234', 'joao@example.com');
    expect(controller.state.error, contains('DDD'));

    await controller.start('(11) 98765-4321', 'sem-arroba');
    expect(controller.state.error, contains('email'));

    expect(api.calls, isEmpty);
  });

  test('should_show_the_neutral_message_and_ask_for_the_email_code_after_start', () async {
    await controller.start('(11) 98765-4321', 'joao@example.com');

    expect(api.calls, ['start:11987654321:joao@example.com']);
    expect(controller.state.step, AppAccessStep.emailCode);
    expect(controller.state.info, contains('Se houver cadastro'));
  });

  test('should_follow_the_happy_path_email_then_whatsapp_then_password', () async {
    api.nextSteps.addAll(['phone_code', 'password']);
    await controller.start('11987654321', 'joao@example.com');

    await controller.verifyCode('111111');
    expect(controller.state.step, AppAccessStep.phoneCode);
    expect(controller.state.emailVerified, isTrue);

    await controller.verifyCode('222222');
    expect(controller.state.step, AppAccessStep.password);

    await controller.complete('nova-senha-123', 'nova-senha-123');
    expect(api.calls, [
      'start:11987654321:joao@example.com',
      'verify:email:111111',
      'verify:phone:222222',
      'complete:nova-senha-123',
    ]);
    expect(storage.saved, 'jwt-token');
    expect(refresh.value, 1);
  });

  test('should_go_through_whatsapp_and_confirm_the_email_when_the_email_did_not_arrive', () async {
    api.nextSteps.addAll(['confirm_email', 'password']);
    await controller.start('11987654321', 'errado@example.com');

    await controller.useWhatsApp();
    expect(controller.state.step, AppAccessStep.phoneCode);

    await controller.verifyCode('222222');
    expect(controller.state.step, AppAccessStep.confirmEmail);

    await controller.confirmEmail('certo@example.com');
    expect(controller.state.step, AppAccessStep.emailCode);
    expect(controller.state.email, 'certo@example.com');

    await controller.verifyCode('333333');
    expect(controller.state.step, AppAccessStep.password);
    expect(api.calls, [
      'start:11987654321:errado@example.com',
      'whatsapp',
      'verify:phone:222222',
      'email:certo@example.com',
      'verify:email:333333',
    ]);
  });

  test('should_reject_mismatched_passwords_without_calling_the_api', () async {
    api.nextSteps.addAll(['phone_code', 'password']);
    await controller.start('11987654321', 'joao@example.com');
    await controller.verifyCode('111111');
    await controller.verifyCode('222222');

    await controller.complete('nova-senha-123', 'outra-senha-123');

    expect(controller.state.error, contains('não conferem'));
    expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
  });

  test('should_show_the_backend_message_and_stay_on_the_step_when_the_code_is_wrong', () async {
    await controller.start('11987654321', 'joao@example.com');
    api.verifyError = DioException(
      requestOptions: RequestOptions(path: '/auth/app-access/verify'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/app-access/verify'),
        statusCode: 401,
        data: {'message': 'Código inválido ou expirado'},
      ),
    );

    await controller.verifyCode('000000');

    expect(controller.state.error, 'Código inválido ou expirado');
    expect(controller.state.step, AppAccessStep.emailCode);
  });
}
