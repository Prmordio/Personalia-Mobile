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

  Future<String> ask(String text) async {
    final response = await _dio.post('/app/assistant/message', data: {'text': text});
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
