import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_rule_set_repository.dart';
import '../data/execution_analysis_api.dart';
import '../data/execution_recorder.dart';
import '../data/keyframe_extractor.dart';
import '../domain/exercise_rule_set.dart';
import '../domain/execution_report.dart';
import '../domain/keyframe_selector.dart';
import '../domain/pose_frame.dart';
import '../domain/rule_engine.dart';

enum ExecutionPhase { idle, analyzing, noReps, result }

class ExecutionAnalysisState {
  const ExecutionAnalysisState({
    this.phase = ExecutionPhase.idle,
    this.exerciseName = '',
    this.videoPath,
    this.frames = const [],
    this.report,
    this.feedback,
    this.feedbackLoading = false,
    this.feedbackFailed = false,
  });

  final ExecutionPhase phase;
  final String exerciseName;
  final String? videoPath;
  final List<PoseFrame> frames;
  final ExecutionReport? report;
  final ExecutionFeedback? feedback;

  /// Resultado medido aparece na hora; o texto da IA chega depois (ou não — fallback local).
  final bool feedbackLoading;
  final bool feedbackFailed;

  ExecutionAnalysisState copyWith({
    ExecutionPhase? phase,
    ExecutionReport? report,
    ExecutionFeedback? feedback,
    bool? feedbackLoading,
    bool? feedbackFailed,
  }) =>
      ExecutionAnalysisState(
        phase: phase ?? this.phase,
        exerciseName: exerciseName,
        videoPath: videoPath,
        frames: frames,
        report: report ?? this.report,
        feedback: feedback ?? this.feedback,
        feedbackLoading: feedbackLoading ?? this.feedbackLoading,
        feedbackFailed: feedbackFailed ?? this.feedbackFailed,
      );
}

/// Orquestra a análise depois da gravação: regras on-device (instantâneo) → keyframes →
/// feedback da IA. Não conhece câmera nem ML Kit.
class ExecutionAnalysisController extends StateNotifier<ExecutionAnalysisState> {
  ExecutionAnalysisController({
    required RuleSetRepository ruleSets,
    required KeyframeExtractor keyframes,
    required ExecutionAnalysisApi api,
  })  : _ruleSets = ruleSets,
        _keyframes = keyframes,
        _api = api,
        super(const ExecutionAnalysisState());

  final RuleSetRepository _ruleSets;
  final KeyframeExtractor _keyframes;
  final ExecutionAnalysisApi _api;

  Future<void> analyze({
    required String exerciseKey,
    required String exerciseName,
    required RecordedSet recorded,
    required String language,
  }) async {
    state = ExecutionAnalysisState(
      phase: ExecutionPhase.analyzing,
      exerciseName: exerciseName,
      videoPath: recorded.videoPath,
      frames: recorded.frames,
    );

    final ruleSet = await _ruleSets.load(exerciseKey);
    final report = RuleEngine(ruleSet).evaluate(recorded.frames);
    if (!report.hasReps) {
      state = state.copyWith(phase: ExecutionPhase.noReps, report: report);
      return;
    }
    state = state.copyWith(phase: ExecutionPhase.result, report: report, feedbackLoading: true);

    try {
      final frames = await _keyframes.extract(recorded.videoPath, selectKeyframes(report));
      final feedback = await _api.submit(
        exerciseName: exerciseName,
        report: report,
        keyframes: frames,
        language: language,
      );
      if (!mounted) return;
      state = state.copyWith(feedback: feedback, feedbackLoading: false, feedbackFailed: feedback.feedback == null);
    } catch (e) {
      debugPrint('execution feedback failed: $e');
      if (!mounted) return;
      state = state.copyWith(feedbackLoading: false, feedbackFailed: true);
    }
  }
}

final ruleSetRepositoryProvider = Provider<RuleSetRepository>((ref) => AssetRuleSetRepository());
final keyframeExtractorProvider = Provider<KeyframeExtractor>((ref) => const KeyframeExtractor());

final executionAnalysisProvider =
    StateNotifierProvider.autoDispose<ExecutionAnalysisController, ExecutionAnalysisState>(
  (ref) => ExecutionAnalysisController(
    ruleSets: ref.watch(ruleSetRepositoryProvider),
    keyframes: ref.watch(keyframeExtractorProvider),
    api: ref.watch(executionAnalysisApiProvider),
  ),
);
