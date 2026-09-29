import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

/// Foto do aparelho do exercício, da base formada pelas fotos que os usuários mandam
/// (GET /agent/exercise-image). null = ainda não há foto para esse exercício.
/// Sem autoDispose: cada imagem é baixada uma vez por sessão, mesmo rolando a lista.
final exerciseImageProvider = FutureProvider.family<Uint8List?, String>((ref, exerciseName) async {
  final name = exerciseName.trim();
  if (name.isEmpty) return null;
  try {
    final response = await ref.watch(apiClientProvider).dio.get<List<int>>(
          '/agent/exercise-image',
          queryParameters: {'name': name},
          options: Options(responseType: ResponseType.bytes),
        );
    final bytes = response.data;
    return bytes == null || bytes.isEmpty ? null : Uint8List.fromList(bytes);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});
