import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/features/auth/data/auth_api.dart';
import 'package:personalia_app/features/auth/state/signup_controller.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());

  final calls = <String>[];
  DioException? startError;
  DioException? verifyError;
  DioException? phoneStartError;
  DioException? phoneVerifyError;

  @override
  Future<String> startSignup(String email) async {
    calls.add('start:$email');
    if (startError != null) throw startError!;
    return 'session-${calls.length}';
  }

  /// O que o backend responde no verify: o email é de uma conta do WhatsApp?
  bool linkAccount = false;
  DioException? completeError;

  @override
  Future<bool> verifySignupCode(String sessionId, String code) async {
    calls.add('verify:$sessionId:$code');
    if (verifyError != null) throw verifyError!;
    return linkAccount;
  }

  @override
  Future<String> completeSignup(String sessionId, String password) async {
    calls.add('complete:$sessionId:$password');
    if (completeError != null) throw completeError!;
    return 'jwt-token';
  }

  @override
  Future<void> requestSignupPhoneCode(String sessionId, String phone) async {
    calls.add('phone-start:$sessionId:$phone');
    if (phoneStartError != null) throw phoneStartError!;
  }

  @override
  Future<void> verifySignupPhone(String sessionId, String code) async {
    calls.add('phone-verify:$sessionId:$code');
    if (phoneVerifyError != null) throw phoneVerifyError!;
  }
}

class _FakeTokenStorage extends TokenStorage {
  String? saved;

  @override
  Future<void> save(String token) async => saved = token;
}

DioException _httpError(int status, String message) {
  final options = RequestOptions(path: '/auth/signup');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: {'message': message}),
  );
}

void main() {
  late _FakeAuthApi api;
  late _FakeTokenStorage storage;
  late ValueNotifier<int> refresh;
  late SignupController controller;

  setUp(() {
    api = _FakeAuthApi();
    storage = _FakeTokenStorage();
    refresh = ValueNotifier(0);
    controller = SignupController(api, storage, refresh);
  });

  Future<void> reachPasswordStep() async {
    await controller.requestCode('maria@example.com');
    await controller.verifyCode('123456');
  }

  test('should_return_error_when_email_is_invalid', () async {
    await controller.requestCode('sem-arroba');

    expect(controller.state.error, 'errAppAccessEmail');
    expect(controller.state.step, SignupStep.email);
    expect(api.calls, isEmpty);
  });

  test('should_send_code_to_normalized_email_and_move_to_code_step', () async {
    await controller.requestCode('  Maria@Example.com ');

    expect(api.calls, ['start:maria@example.com']);
    expect(controller.state.step, SignupStep.code);
    expect(controller.state.info, 'appAccessInfoCodeSentTo:maria@example.com');
  });

  test('should_offer_login_when_email_already_has_an_account', () async {
    api.startError = _httpError(409, 'Este email já tem uma conta.');

    await controller.requestCode('maria@example.com');

    expect(controller.state.emailTaken, isTrue);
    expect(controller.state.error, 'Este email já tem uma conta.');
    expect(controller.state.step, SignupStep.email);
  });

  test('should_offer_sending_again_after_editing_an_email_that_has_an_account', () async {
    api.startError = _httpError(409, 'Este email já tem uma conta.');
    await controller.requestCode('maria@example.com');
    expect(controller.state.emailTaken, isTrue);

    controller.editEmail();

    expect(controller.state.emailTaken, isFalse);
    expect(controller.state.error, isNull);
    expect(controller.state.step, SignupStep.email);
  });

  test('should_stay_on_code_step_when_code_is_wrong', () async {
    await controller.requestCode('maria@example.com');
    api.verifyError = _httpError(401, 'Código inválido ou expirado');

    await controller.verifyCode('000000');

    expect(controller.state.step, SignupStep.code);
    expect(controller.state.error, 'Código inválido ou expirado');
  });

  test('should_reject_code_with_wrong_length_without_calling_the_api', () async {
    await controller.requestCode('maria@example.com');

    await controller.verifyCode('123');

    expect(controller.state.error, 'errAuthCodeLength');
    expect(api.calls, ['start:maria@example.com']);
  });

  test('should_use_the_new_session_after_resending_the_code', () async {
    await controller.requestCode('maria@example.com');
    await controller.resendCode();
    await controller.verifyCode('123456');

    expect(api.calls.last, 'verify:session-2:123456');
  });

  test('should_reject_short_or_mismatched_password_without_calling_the_api', () async {
    await reachPasswordStep();

    await controller.createAccount(password: 'curta', confirmation: 'curta');
    expect(controller.state.error, 'errAuthPasswordTooShort');

    await controller.createAccount(password: 'senha-forte', confirmation: 'outra-senha');
    expect(controller.state.error, 'errPasswordMismatch');

    expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
  });

  test('should_create_account_without_phone_and_log_in', () async {
    await reachPasswordStep();

    await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte');

    expect(api.calls.last, 'complete:session-1:senha-forte');
    expect(storage.saved, 'jwt-token');
    expect(refresh.value, 1);
  });

  test('should_reject_invalid_phone_before_creating_the_account', () async {
    await reachPasswordStep();

    await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte', phone: '1234');

    expect(controller.state.error, 'errSignupPhoneInvalid');
    expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
  });

  group('with phone', () {
    Future<void> createWithPhone() async {
      await reachPasswordStep();
      await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte', phone: '(11) 98765-4321');
    }

    test('should_send_sms_before_creating_the_account', () async {
      await createWithPhone();

      expect(api.calls.last, 'phone-start:session-1:11987654321');
      expect(controller.state.step, SignupStep.phoneCode);
      expect(controller.state.info, 'signupPhoneCodeSentTo:11987654321');
      // A conta só é criada depois do SMS: desistir aqui não deixa conta pela metade.
      expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
      expect(storage.saved, isNull);
    });

    test('should_create_the_account_and_log_in_after_confirming_the_sms_code', () async {
      await createWithPhone();

      await controller.verifyPhoneCode('654321');

      expect(api.calls.sublist(api.calls.length - 2), ['phone-verify:session-1:654321', 'complete:session-1:senha-forte']);
      expect(storage.saved, 'jwt-token');
      expect(refresh.value, 1);
    });

    test('should_stay_on_sms_step_when_code_is_wrong', () async {
      await createWithPhone();
      api.phoneVerifyError = _httpError(401, 'Código inválido ou expirado');

      await controller.verifyPhoneCode('000000');

      expect(controller.state.step, SignupStep.phoneCode);
      expect(controller.state.error, 'Código inválido ou expirado');
      expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
      expect(storage.saved, isNull);
    });

    test('should_allow_skipping_when_sms_cannot_be_sent', () async {
      api.phoneStartError = _httpError(503, 'Não foi possível enviar o SMS agora.');
      await createWithPhone();

      expect(controller.state.step, SignupStep.phoneCode);
      expect(controller.state.error, 'Não foi possível enviar o SMS agora.');

      await controller.skipPhone();

      expect(api.calls.last, 'complete:session-1:senha-forte');
      expect(storage.saved, 'jwt-token');
      expect(refresh.value, 1);
    });

    test('should_go_back_to_password_step_to_change_the_phone', () async {
      await createWithPhone();

      controller.backToPassword();

      expect(controller.state.step, SignupStep.password);
      expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
    });
  });

  group('with email of a WhatsApp account', () {
    setUp(() => api.linkAccount = true);

    test('should_require_the_phone', () async {
      await reachPasswordStep();
      expect(controller.state.linkAccount, isTrue);

      await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte');

      expect(controller.state.error, 'errSignupPhoneRequired');
      expect(controller.state.step, SignupStep.password);
      expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
    });

    test('should_return_to_password_step_when_phone_is_not_the_whatsapp_one', () async {
      api.phoneStartError = _httpError(400, 'Este não é o telefone da sua conta do WhatsApp.');
      await reachPasswordStep();

      await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte', phone: '11912345678');

      expect(controller.state.step, SignupStep.password);
      expect(controller.state.error, 'Este não é o telefone da sua conta do WhatsApp.');
    });

    test('should_not_allow_skipping_the_phone', () async {
      await reachPasswordStep();
      await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte', phone: '11987654321');

      await controller.skipPhone();

      expect(api.calls.where((c) => c.startsWith('complete')), isEmpty);
      expect(storage.saved, isNull);
    });

    test('should_log_in_to_the_linked_account_after_the_sms_code', () async {
      await reachPasswordStep();
      await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte', phone: '11987654321');

      await controller.verifyPhoneCode('654321');

      expect(api.calls.last, 'complete:session-1:senha-forte');
      expect(storage.saved, 'jwt-token');
      expect(refresh.value, 1);
    });

    test('should_stay_when_complete_is_rejected', () async {
      api.completeError = _httpError(409, 'Confirme o telefone dela para continuar.');
      await reachPasswordStep();
      await controller.createAccount(password: 'senha-forte', confirmation: 'senha-forte', phone: '11987654321');

      await controller.verifyPhoneCode('654321');

      expect(controller.state.error, 'Confirme o telefone dela para continuar.');
      expect(controller.state.loading, isFalse);
      expect(storage.saved, isNull);
    });
  });
}
