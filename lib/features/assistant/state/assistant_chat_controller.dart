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

const _welcome = ChatMessage(
  fromUser: false,
  text: 'Oi! 👋 Sou o assistente do PersonalIA. Pergunte sobre treino, exercícios, alimentação ou recuperação — '
      'ou mande a foto de um aparelho da academia que eu te digo qual exercício fazer nele. 📸',
);
const _genericError = 'Não consegui responder agora. Tente de novo em instantes.';

/// Conversa do chat de dúvidas. Fica em memória durante a sessão (não é autoDispose):
/// fechar e reabrir o chat mantém o histórico.
class AssistantChatController extends StateNotifier<List<ChatMessage>> {
  AssistantChatController(this._api) : super(const [_welcome]);

  final AssistantApi _api;

  bool get isWaiting => state.isNotEmpty && state.last.pending;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || isWaiting) return;
    _push(ChatMessage(fromUser: true, text: text));
    try {
      _resolve(ChatMessage(fromUser: false, text: await _api.ask(text)));
    } on DioException catch (e) {
      _resolve(ChatMessage(fromUser: false, text: _messageFrom(e)));
    }
  }

  Future<void> sendPhoto(Uint8List bytes, String mimeType) async {
    if (isWaiting) return;
    _push(ChatMessage(fromUser: true, text: '', image: bytes));
    try {
      final result = await _api.identifyEquipment(bytes, mimeType);
      _resolve(
        result.found
            ? ChatMessage(fromUser: false, text: _describe(result), exerciseName: result.primaryExercise)
            : ChatMessage(fromUser: false, text: result.message ?? 'Não identifiquei um aparelho nessa foto.'),
      );
    } on DioException catch (e) {
      _resolve(ChatMessage(fromUser: false, text: _messageFrom(e)));
    }
  }

  void _push(ChatMessage userMessage) {
    state = [...state, userMessage, const ChatMessage(fromUser: false, text: '', pending: true)];
  }

  void _resolve(ChatMessage reply) {
    if (!mounted) return;
    state = [...state.where((m) => !m.pending), reply];
  }

  String _describe(EquipmentIdentification r) {
    final lines = <String>[
      if ((r.equipmentName ?? '').isNotEmpty) '🏋️ ${r.equipmentName}',
      if ((r.primaryExercise ?? '').isNotEmpty) 'Exercício: ${r.primaryExercise}',
      if (r.muscleGroups.isNotEmpty) 'Músculos: ${r.muscleGroups.join(', ')}',
    ];
    return [lines.join('\n'), if ((r.description ?? '').isNotEmpty) r.description!].where((s) => s.isNotEmpty).join('\n\n');
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['message'] : null;
    return message is String ? message : _genericError;
  }
}

final assistantChatProvider = StateNotifierProvider<AssistantChatController, List<ChatMessage>>((ref) {
  return AssistantChatController(ref.watch(assistantApiProvider));
});
