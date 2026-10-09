import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class EquipmentIdentification {
  EquipmentIdentification({
    required this.found,
    this.equipmentName,
    this.primaryExercise,
    this.muscleGroups = const [],
    this.description,
    this.message,
  });

  final bool found;
  final String? equipmentName;
  final String? primaryExercise;
  final List<String> muscleGroups;
  final String? description;

  /// Explicação quando não é um aparelho (found = false).
  final String? message;

  factory EquipmentIdentification.fromJson(Map<String, dynamic> json) => EquipmentIdentification(
        found: json['found'] == true,
        equipmentName: json['equipmentName'],
        primaryExercise: json['primaryExercise'],
        muscleGroups: List<String>.from(json['muscleGroups'] ?? const []),
        description: json['description'],
        message: json['message'],
      );
}

/// Chat de dúvidas do app: texto vai para a triagem de tema + IA; foto vai para a
/// identificação de aparelho (mesma análise das fotos do WhatsApp).
class AssistantApi {
  AssistantApi(this._dio);
  final Dio _dio;

  /// Streaming SSE: classifica primeiro, depois faz yield de cada chunk de texto.
  /// A bolha do chat é atualizada conforme os chunks chegam — typewriter effect.
  Stream<String> askStream(String text) {
    final controller = StreamController<String>();

    _dio
        .post<ResponseBody>(
      '/app/assistant/message-stream',
      data: {'text': text},
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(seconds: 45),
      ),
    )
        .then((response) async {
      final body = response.data;
      if (body == null) {
        controller.addError('no body');
        await controller.close();
        return;
      }

      final buffer = StringBuffer();
      await for (final chunk in body.stream.cast<List<int>>().transform(utf8.decoder)) {
        buffer.write(chunk);
        // Process all complete SSE lines (split on \n, keep last incomplete one).
        final content = buffer.toString();
        final lines = content.split('\n');
        buffer.clear();
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (!line.startsWith('data:')) continue;
          final jsonStr = line.substring(5).trim();
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            if (data['done'] == true) {
              await controller.close();
              return;
            }
            if (data['error'] == true) {
              final msg = (data['message'] as String?) ?? 'Erro desconhecido';
              controller.addError(msg);
              await controller.close();
              return;
            }
            final c = data['chunk'] as String?;
            if (c != null && c.isNotEmpty) controller.add(c);
          } catch (_) {
            // malformed line — ignore
          }
        }
        if (lines.isNotEmpty) buffer.write(lines.last);
      }
      await controller.close();
    }).catchError((Object e) async {
      controller.addError(e);
      await controller.close();
    });

    return controller.stream;
  }

  Future<String> ask(String text) async {
    final response = await _dio.post(
      '/app/assistant/message',
      data: {'text': text},
      // Classification and the answer each have a 30s backend timeout.
      options: Options(receiveTimeout: const Duration(seconds: 75)),
    );
    return (response.data['reply'] as String?) ?? '';
  }

  Future<EquipmentIdentification> identifyEquipment(Uint8List bytes, String mimeType) async {
    final response = await _dio.post(
      '/app/assistant/photo',
      data: {'imageBase64': base64Encode(bytes), 'mimeType': mimeType},
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return EquipmentIdentification.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}

final assistantApiProvider = Provider<AssistantApi>((ref) => AssistantApi(ref.watch(apiClientProvider).dio));
