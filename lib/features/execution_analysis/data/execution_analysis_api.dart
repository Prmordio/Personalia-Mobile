import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/execution_report.dart';
import 'keyframe_extractor.dart';

class ExtraIssue {
  const ExtraIssue({required this.id, required this.label, required this.reps});
  final String id;
  final String label;
  final List<int> reps;

  factory ExtraIssue.fromJson(Map<String, dynamic> json) => ExtraIssue(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        reps: [for (final r in json['reps'] as List? ?? const []) (r as num).toInt()],
      );
}

class ExecutionFeedback {
  const ExecutionFeedback({this.feedback, this.confirmedIssueIds = const [], this.extraIssues = const []});

  /// null quando a IA não respondeu — a tela usa os cues locais do rule set.
  final String? feedback;
  final List<String> confirmedIssueIds;
  final List<ExtraIssue> extraIssues;

  factory ExecutionFeedback.fromJson(Map<String, dynamic> json) => ExecutionFeedback(
        feedback: (json['feedback'] as String?)?.trim().isNotEmpty == true ? json['feedback'] as String : null,
        confirmedIssueIds: List<String>.from(json['confirmedIssueIds'] as List? ?? const []),
        extraIssues: [
          for (final e in json['extraIssues'] as List? ?? const []) ExtraIssue.fromJson(e as Map<String, dynamic>),
        ],
      );
}

/// Envia o relatório medido + keyframes; o vídeo nunca sai do aparelho.
class ExecutionAnalysisApi {
  ExecutionAnalysisApi(this._dio);
  final Dio _dio;

  Future<ExecutionFeedback> submit({
    required String exerciseName,
    required ExecutionReport report,
    required List<Keyframe> keyframes,
    required String language,
  }) async {
    final response = await _dio.post(
      '/app/execution-analysis',
      data: {
        'consent': true,
        'exerciseName': exerciseName,
        'report': report.toJson(),
        'keyframes': [
          for (final k in keyframes) {'base64': base64Encode(k.jpeg), 'mimeType': 'image/jpeg', 'label': k.label},
        ],
        'language': language,
      },
      options: Options(receiveTimeout: const Duration(seconds: 45), sendTimeout: const Duration(seconds: 45)),
    );
    return ExecutionFeedback.fromJson(response.data as Map<String, dynamic>);
  }
}

final executionAnalysisApiProvider =
    Provider<ExecutionAnalysisApi>((ref) => ExecutionAnalysisApi(ref.watch(apiClientProvider).dio));
