import '../../../core/telemetry/app_telemetry.dart';
import '../../../core/locale/locale_controller.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/assistant_api.dart';

class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text, this.image, this.exerciseName, this.pending = false});

  final bool fromUser;
  final String text;
  final Uint8List? image;

  /// Exercício identificado numa foto — a bolha oferece "Ver vídeos".
  final String? exerciseName;

  /// Bolha "digitando..." enquanto espera a resposta.
  final bool pending;
}

String _genericErrorFor(String language) {
  switch (language) {
    case 'en':
      return 'Could not respond right now. Please try again in a moment.';
    case 'es':
      return 'No pude responder ahora. Inténtalo de nuevo en un momento.';
    default:
      return 'Não consegui responder agora. Tente de novo em instantes.';
  }
}

String _welcomeText(String? languageCode) {
  switch (languageCode) {
    case 'en':
      return 'Hi! 👋 I\'m the PersonalIA assistant. Ask me about training, exercises, nutrition or recovery — or send a photo of a gym machine and I\'ll tell you what exercise to do on it. 📸';
    case 'es':
      return '¡Hola! 👋 Soy el asistente de PersonalIA. Pregúntame sobre entrenamiento, ejercicios, nutrición o recuperación — o envía la foto de una máquina del gimnasio y te digo qué ejercicio hacer. 📸';
    default:
      return 'Oi! 👋 Sou o assistente do PersonalIA. Pergunte sobre treino, exercícios, alimentação ou recuperação — ou mande a foto de um aparelho da academia que eu te digo qual exercício fazer nele. 📸';
  }
}

/// Conversa do chat de dúvidas. Fica em memória durante a sessão (não é autoDispose):
/// fechar e reabrir o chat mantém o histórico.
class AssistantChatController extends StateNotifier<List<ChatMessage>> {
  AssistantChatController(this._api, {String? languageCode})
      : super([ChatMessage(fromUser: false, text: _welcomeText(languageCode))]);

  final AssistantApi _api;

  bool get isWaiting => state.isNotEmpty && state.last.pending;

  Future<void> send(String rawText, {String language = 'pt-BR'}) async {
    final text = rawText.trim();
    if (text.isEmpty || isWaiting) return;
    AppTelemetry.instance.event('assistant_message_sent');
    _push(ChatMessage(fromUser: true, text: text));

    final buffer = StringBuffer();
    try {
      await for (final chunk in _api.askStream(text, language: language)) {
        if (!mounted) return;
        buffer.write(chunk);
        // Atualiza a bolha em tempo real (efeito typewriter) mantendo o pending=true.
        state = [
          ...state.where((m) => !m.pending),
          ChatMessage(fromUser: false, text: buffer.toString(), pending: true),
        ];
      }
      if (!mounted) return;
      final reply = buffer.toString();
      _resolve(ChatMessage(fromUser: false, text: reply.isEmpty ? _genericErrorFor(language) : reply));
    } on DioException catch (e) {
      _resolve(ChatMessage(fromUser: false, text: _messageFrom(e, language)));
    } catch (_) {
      _resolve(ChatMessage(fromUser: false, text: buffer.isEmpty ? _genericErrorFor(language) : buffer.toString()));
    }
  }

  Future<void> sendPhoto(Uint8List bytes, String mimeType, {String language = 'pt'}) async {
    if (isWaiting) return;
    _push(ChatMessage(fromUser: true, text: '', image: bytes));
    try {
      final result = await _api.identifyEquipment(bytes, mimeType, language: language);
      _resolve(
        result.found
            ? ChatMessage(fromUser: false, text: _describe(result, language), exerciseName: result.primaryExercise)
            : ChatMessage(fromUser: false, text: result.message ?? _genericErrorFor(language)),
      );
    } on DioException catch (e) {
      _resolve(ChatMessage(fromUser: false, text: _messageFrom(e, language)));
    }
  }

  void _push(ChatMessage userMessage) {
    state = [...state, userMessage, const ChatMessage(fromUser: false, text: '', pending: true)];
  }

  void _resolve(ChatMessage reply) {
    if (!mounted) return;
    state = [...state.where((m) => !m.pending), reply];
  }

  String _describe(EquipmentIdentification r, [String language = 'pt']) {
    final exerciseLabel = language == 'en' ? 'Exercise' : language == 'es' ? 'Ejercicio' : 'Exercício';
    final musclesLabel = language == 'en' ? 'Muscles' : language == 'es' ? 'Músculos' : 'Músculos';
    final lines = <String>[
      if ((r.equipmentName ?? '').isNotEmpty) '🏋️ ${r.equipmentName}',
      if ((r.primaryExercise ?? '').isNotEmpty) '$exerciseLabel: ${r.primaryExercise}',
      if (r.muscleGroups.isNotEmpty) '$musclesLabel: ${r.muscleGroups.join(', ')}',
    ];
    return [lines.join('\n'), if ((r.description ?? '').isNotEmpty) r.description!].where((s) => s.isNotEmpty).join('\n\n');
  }

  String _messageFrom(DioException e, [String language = 'pt']) {
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    return message is String ? message : _genericErrorFor(language);
  }
}

final assistantChatProvider = StateNotifierProvider<AssistantChatController, List<ChatMessage>>((ref) {
  final locale = ref.watch(localeProvider);
  return AssistantChatController(ref.watch(assistantApiProvider), languageCode: locale?.languageCode);
});
