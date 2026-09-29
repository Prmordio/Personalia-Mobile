import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/network/token_storage.dart';
import 'package:personalia_app/core/security/biometric_auth.dart';
import 'package:personalia_app/core/security/biometric_credential_storage.dart';
import 'package:personalia_app/features/auth/data/auth_api.dart';
import 'package:personalia_app/features/auth/state/biometric_login_service.dart';

class _FakeBiometricAuth extends BiometricAuth {
  bool available = true;
  bool approve = true;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return approve;
  }
}

class _MemoryCredentialStorage extends BiometricCredentialStorage {
  BiometricCredential? value;

  @override
  Future<BiometricCredential?> read() async => value;

  @override
  Future<void> save(BiometricCredential credential) async => value = credential;

  @override
  Future<void> clear() async => value = null;
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());

  final calls = <String>[];
  int? loginStatusCode;

  @override
  Future<(String, String)> enrollBiometric(String deviceName) async {
    calls.add('enroll');
    return ('cred-1', 'device-token');
  }

  @override
  Future<String> loginWithBiometric(String credentialId, String token) async {
    calls.add('login:$credentialId:$token');
    if (loginStatusCode != null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/biometric/login'),
        response: Response(requestOptions: RequestOptions(path: '/auth/biometric/login'), statusCode: loginStatusCode),
      );
    }
    return 'jwt-token';
  }

  @override
  Future<void> revokeBiometric(String credentialId) async => calls.add('revoke:$credentialId');
}

class _FakeTokenStorage extends TokenStorage {
  String? saved;

  @override
  Future<void> save(String token) async => saved = token;
}

void main() {
  late _FakeAuthApi api;
  late _FakeBiometricAuth biometric;
  late _MemoryCredentialStorage credentials;
  late _FakeTokenStorage tokens;
  late ValueNotifier<int> refresh;
  late BiometricLoginService service;

  setUp(() {
    api = _FakeAuthApi();
    biometric = _FakeBiometricAuth();
    credentials = _MemoryCredentialStorage();
    tokens = _FakeTokenStorage();
    refresh = ValueNotifier(0);
    service = BiometricLoginService(api, biometric, credentials, tokens, refresh);
  });

  test('should_offer_only_when_the_device_has_biometrics_and_it_is_not_enabled', () async {
    expect(await service.canEnable(), isTrue);

    biometric.available = false;
    expect(await service.canEnable(), isFalse);

    biometric.available = true;
    credentials.value = const BiometricCredential(credentialId: 'c', token: 't');
    expect(await service.canEnable(), isFalse);
  });

  test('should_enable_only_after_the_biometric_prompt_succeeds', () async {
    biometric.approve = false;
    expect(await service.enable(), isFalse);
    expect(api.calls, isEmpty);

    biometric.approve = true;
    expect(await service.enable(), isTrue);
    expect(credentials.value?.credentialId, 'cred-1');
    expect(credentials.value?.token, 'device-token');
  });

  test('should_log_in_with_the_stored_credential_after_the_prompt', () async {
    await service.enable();

    expect(await service.login(), BiometricLoginResult.success);
    expect(api.calls.last, 'login:cred-1:device-token');
    expect(tokens.saved, 'jwt-token');
    expect(refresh.value, 1);
  });

  test('should_not_call_the_backend_when_the_prompt_is_cancelled', () async {
    await service.enable();
    biometric.approve = false;

    expect(await service.login(), BiometricLoginResult.cancelled);
    expect(api.calls.where((c) => c.startsWith('login')), isEmpty);
    expect(tokens.saved, isNull);
  });

  test('should_forget_a_revoked_or_expired_credential', () async {
    await service.enable();
    api.loginStatusCode = 401;

    expect(await service.login(), BiometricLoginResult.invalidCredential);
    expect(credentials.value, isNull);
  });

  test('should_keep_the_credential_on_transient_failures', () async {
    await service.enable();
    api.loginStatusCode = 503;

    expect(await service.login(), BiometricLoginResult.failed);
    expect(credentials.value, isNotNull);
  });

  test('should_revoke_and_clear_when_disabled', () async {
    await service.enable();

    await service.disable();

    expect(api.calls.last, 'revoke:cred-1');
    expect(credentials.value, isNull);
  });

  test('should_report_not_enabled_without_prompting', () async {
    expect(await service.login(), BiometricLoginResult.notEnabled);
    expect(biometric.prompts, 0);
  });
}
