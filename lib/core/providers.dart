import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/api_client.dart';
import 'network/device_token_api.dart';
import 'network/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Bumpado sempre que o estado de login muda (login/logout), pra forçar o go_router
/// a reavaliar o redirect (ver core/router/app_router.dart).
final authRefreshProvider = Provider<ValueNotifier<int>>((ref) => ValueNotifier(0));

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final refresh = ref.watch(authRefreshProvider);
  return ApiClient(storage, onUnauthorized: () {
    refresh.value++;
  });
});

final deviceTokenApiProvider = Provider<DeviceTokenApi>((ref) {
  return DeviceTokenApi(ref.watch(apiClientProvider).dio);
});
