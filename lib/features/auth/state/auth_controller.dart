import '../../../core/telemetry/app_telemetry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/auth_api.dart';

enum LoginStep { phone, channel, otp }

class LoginState {
  const LoginState({
    this.step = LoginStep.phone,
    this.phoneNumber = '',
    this.channels = const [],
    this.selectedChannel,
    this.loading = false,
    this.error,
    this.info,
  });

  final LoginStep step;
  final String phoneNumber;
  final List<String> channels;
  final String? selectedChannel;
  final bool loading;
  final String? error;
  final String? info;

  LoginState copyWith({
    LoginStep? step,
    String? phoneNumber,
    List<String>? channels,
    String? selectedChannel,
    bool? loading,
    String? error,
    String? info,
  }) {
    return LoginState(
      step: step ?? this.step,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      channels: channels ?? this.channels,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      loading: loading ?? this.loading,
      error: error,
      info: info,
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider).dio));

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._authApi, this._tokenStorage, this._refresh) : super(const LoginState());

  final AuthApi _authApi;
  final dynamic _tokenStorage;
  final dynamic _refresh;

  Future<void> submitPhone(String phoneNumber) async {
    state = state.copyWith(loading: true, error: null, phoneNumber: phoneNumber);
    try {
      final channels = await _authApi.getChannels(phoneNumber);
      if (channels.length == 1) {
        await _requestAndAdvance(phoneNumber, channels.first, channels);
      } else {
        state = state.copyWith(loading: false, channels: channels, step: LoginStep.channel);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Não foi possível verificar esse número.');
    }
  }

  Future<void> selectChannel(String channel) async {
    await _requestAndAdvance(state.phoneNumber, channel, state.channels);
  }

  Future<void> _requestAndAdvance(String phoneNumber, String channel, List<String> channels) async {
    state = state.copyWith(loading: true, error: null, channels: channels, selectedChannel: channel);
    try {
      await _authApi.requestOtp(phoneNumber, channel);
      state = state.copyWith(loading: false, step: LoginStep.otp);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Não foi possível enviar o código. Tente novamente.');
    }
  }

  Future<void> resendCode() async {
    state = state.copyWith(loading: true, error: null, info: null);
    try {
      await _authApi.requestOtp(state.phoneNumber, state.selectedChannel!);
      state = state.copyWith(loading: false, info: 'Código reenviado.');
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Não foi possível reenviar o código. Tente novamente.');
    }
  }

  Future<bool> verifyCode(String code) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await _authApi.verifyOtp(state.phoneNumber, code);
      await _tokenStorage.save(token);
      AppTelemetry.instance.event('login');
      _refresh.value++;
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Código inválido ou expirado.');
      return false;
    }
  }

  void backToPhone() {
    state = const LoginState();
  }
}

final loginControllerProvider = StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(authRefreshProvider),
  );
});
