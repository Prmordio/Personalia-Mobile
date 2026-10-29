import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase_options.dart';
import '../../onboarding/data/onboarding_api.dart';
import '../data/app_api.dart';

/// Chave do Remote Config com os SHA-256 (hex) dos emails com acesso ilimitado,
/// separados por vírgula/espaço. Só hashes: o Remote Config é legível por qualquer cliente.
const unlimitedAccessRemoteConfigKey = 'unlimited_access_email_hashes';

String hashEmail(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

Set<String> parseEmailHashes(String raw) => raw
    .split(RegExp(r'[\s,]+'))
    .map((hash) => hash.trim().toLowerCase())
    .where((hash) => hash.isNotEmpty)
    .toSet();

Future<Set<String>> _loadRemoteHashes() async {
  // O shell pode montar antes do startup terminar; initializeApp é idempotente.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final config = FirebaseRemoteConfig.instance;
  await config.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  await config.setDefaults(const {unlimitedAccessRemoteConfigKey: ''});
  try {
    await config.fetchAndActivate();
  } catch (_) {
    // Sem rede, vale o último valor ativado.
  }
  return parseEmailHashes(config.getString(unlimitedAccessRemoteConfigKey));
}

final unlimitedAccessHashesProvider = FutureProvider<Set<String>>(
  (ref) => _loadRemoteHashes(),
);

/// Contas liberadas sem assinatura (ex.: conta demo da revisão da Apple). Não altera a
/// assinatura: o "Assinar" e a compra continuam disponíveis para essas contas.
final unlimitedAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final hashes = await ref.watch(unlimitedAccessHashesProvider.future);
  if (hashes.isEmpty) return false;
  final status = await ref.watch(onboardingApiProvider).getStatus();
  final email = status.profile.email;
  return email != null && email.isNotEmpty && hashes.contains(hashEmail(email));
});

/// Libera as áreas de assinante. Considera liberado enquanto carrega (evita piscar
/// de bloqueado para liberado).
final featureAccessProvider = Provider.autoDispose<bool>((ref) {
  final subscribed = ref
      .watch(subscriptionProvider)
      .maybeWhen(data: (s) => s.isValid, orElse: () => true);
  if (subscribed) return true;
  return ref
      .watch(unlimitedAccessProvider)
      .maybeWhen(
        data: (allowed) => allowed,
        loading: () => true,
        orElse: () => false,
      );
});
