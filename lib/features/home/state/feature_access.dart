import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote_config/app_remote_config.dart';
import '../../onboarding/data/onboarding_api.dart';
import '../data/app_api.dart';

/// Chave do Remote Config com os SHA-256 (hex) dos emails com acesso ilimitado,
/// separados por vírgula/espaço. Só hashes: o Remote Config é legível por qualquer cliente.
const unlimitedAccessRemoteConfigKey = RemoteConfigKeys.unlimitedAccessEmailHashes;

String hashEmail(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

Set<String> parseEmailHashes(String raw) => raw
    .split(RegExp(r'[\s,]+'))
    .map((hash) => hash.trim().toLowerCase())
    .where((hash) => hash.isNotEmpty)
    .toSet();

final unlimitedAccessHashesProvider = FutureProvider<Set<String>>((ref) async {
  final config = await ref.watch(remoteConfigProvider.future);
  return parseEmailHashes(config.getString(unlimitedAccessRemoteConfigKey));
});

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
/// de bloqueado para liberado); erro de rede/servidor conta como bloqueado.
final featureAccessProvider = Provider.autoDispose<bool>((ref) {
  // Falha fechado: erro ao consultar a assinatura NÃO libera as áreas pagas (antes,
  // bloquear /app/subscription num proxy destravava a UI). Carregando = liberado só para
  // não piscar; o servidor exige assinatura nos endpoints pagos de qualquer forma.
  final subscribed = ref
      .watch(subscriptionProvider)
      .when(data: (s) => s.isValid, loading: () => true, error: (_, _) => false);
  if (subscribed) return true;
  return ref
      .watch(unlimitedAccessProvider)
      .maybeWhen(
        data: (allowed) => allowed,
        loading: () => true,
        orElse: () => false,
      );
});
