import 'package:dio/dio.dart';
import 'e2e_env.dart';

/// Caixa de entrada do Mailpit: recebe os emails de dev e, com SMS_TRANSPORT=mailbox no
/// notifier, também os SMS (endereço `sms+<número com DDI>@sms.local`).
class Mailbox {
  Mailbox() : _dio = Dio(BaseOptions(baseUrl: E2eEnv.mailpitUrl));
  final Dio _dio;

  static String smsAddress(String phoneDigits) {
    final digits = phoneDigits.replaceAll(RegExp(r'\D'), '');
    final withCountry = digits.length <= 11 ? '55$digits' : digits;
    return 'sms+$withCountry@sms.local';
  }

  Future<List<Map<String, dynamic>>> messagesTo(String address) async {
    final response = await _dio.get('/api/v1/search', queryParameters: {'query': 'to:"$address"'});
    return List<Map<String, dynamic>>.from(response.data['messages'] as List);
  }

  /// Código de 6 dígitos da mensagem mais recente para [address] (espera ela chegar).
  /// [after] = quantas mensagens já existiam antes do envio, para não pegar um código antigo.
  Future<String> waitForCode(String address, {int after = 0, Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final messages = await messagesTo(address);
      if (messages.length > after) {
        final code = RegExp(r'\b(\d{6})\b').firstMatch(messages.first['Snippet'] as String? ?? '');
        if (code != null) return code.group(1)!;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw StateError('Nenhum código chegou para $address em ${timeout.inSeconds}s');
  }
}
