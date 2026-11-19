import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Header verificado pelo gateway (personalia-gateway/src/auth/guards/app-check.guard.ts).
const appCheckHeader = 'X-Firebase-AppCheck';

bool _appCheckActive = false;

/// Ativa o Firebase App Check: atesta que as chamadas vêm do app original instalado da loja
/// num aparelho íntegro (Play Integrity / App Attest). Em debug usa o provider de debug —
/// o token impresso no log precisa ser cadastrado no console do Firebase para passar no
/// modo enforce.
Future<void> activateAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: kReleaseMode ? AppleProvider.appAttestWithDeviceCheckFallback : AppleProvider.debug,
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  _appCheckActive = true;
}

/// Fonte do token (abstração para testes).
typedef AppCheckTokenSource = Future<String?> Function();

Future<String?> _firebaseToken() async {
  // Antes da ativação (startup ainda rodando) não espera: segue sem token.
  if (!_appCheckActive || Firebase.apps.isEmpty) return null;
  return FirebaseAppCheck.instance.getToken();
}

/// Anexa o token do App Check em toda requisição. Nunca bloqueia a chamada: sem token
/// (Firebase ainda iniciando, atestação indisponível) segue sem o header — quem decide
/// rejeitar é o gateway (modo enforce).
class AppCheckInterceptor extends Interceptor {
  AppCheckInterceptor({AppCheckTokenSource? tokenSource, this.timeout = const Duration(seconds: 3)})
      : _tokenSource = tokenSource ?? _firebaseToken;

  final AppCheckTokenSource _tokenSource;
  final Duration timeout;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _tokenSource().timeout(timeout);
      if (token != null && token.isNotEmpty) options.headers[appCheckHeader] = token;
    } catch (error) {
      debugPrint('[AppCheck] token unavailable: ${error.runtimeType}');
    }
    handler.next(options);
  }
}
