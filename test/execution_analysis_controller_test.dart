import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/execution_analysis/data/execution_analysis_api.dart';
import 'package:personalia_app/features/execution_analysis/data/execution_recorder.dart';
import 'package:personalia_app/features/execution_analysis/data/keyframe_extractor.dart';
import 'package:personalia_app/features/execution_analysis/domain/exercise_rule_set.dart';
import 'package:personalia_app/features/execution_analysis/domain/execution_report.dart';
import 'package:personalia_app/features/execution_analysis/domain/keyframe_selector.dart';
import 'package:personalia_app/features/execution_analysis/domain/pose_frame.dart';
import 'package:personalia_app/features/execution_analysis/presentation/widgets/skeleton_overlay_painter.dart';
import 'package:personalia_app/features/execution_analysis/state/execution_analysis_controller.dart';

class _FileRuleSets implements RuleSetRepository {
  @override
  Future<ExerciseRuleSet> load(String exerciseKey) async => ExerciseRuleSet.fromJson(
        jsonDecode(File('assets/execution_rules/$exerciseKey.json').readAsStringSync()) as Map<String, dynamic>,
      );
}

class _FakeKeyframes extends KeyframeExtractor {
  List<KeyframeRequest> requested = [];

  @override
  Future<List<Keyframe>> extract(String videoPath, List<KeyframeRequest> requests) async {
    requested = requests;
    return [for (final r in requests) Keyframe(jpeg: Uint8List.fromList([0xff, 0xd8]), label: r.label)];
  }
}

class _FakeApi extends ExecutionAnalysisApi {
  _FakeApi() : super(Dio());
  ExecutionFeedback? response;
  Object? error;
  ExecutionReport? sentReport;
  int sentKeyframes = 0;

  @override
  Future<ExecutionFeedback> submit({
    required String exerciseName,
    required ExecutionReport report,
    required List<Keyframe> keyframes,
    required String language,
  }) async {
    sentReport = report;
    sentKeyframes = keyframes.length;
    if (error != null) throw error!;
    return response!;
  }
}

/// Agachamentos lado direito: coxa fixa na horizontal e a canela gira para formar o
/// ângulo do joelho, que oscila entre 175° e [bottom].
List<PoseFrame> _squats(int reps, {double bottom = 80}) {
  final frames = <PoseFrame>[];
  var t = 0;
  for (var r = 0; r < reps; r++) {
    for (final knee in [175.0, 150, 120, bottom, bottom, 120, 150, 175, 175]) {
      final a = knee * math.pi / 180;
      frames.add(PoseFrame(t, {
        Landmark.rightShoulder: const PosePoint(0.4, 0.2, 0.95),
        Landmark.rightHip: const PosePoint(0.4, 0.5, 0.95),
        Landmark.rightKnee: const PosePoint(0.6, 0.5, 0.95),
        Landmark.rightAnkle: PosePoint(0.6 - 0.2 * math.cos(a), 0.5 + 0.2 * math.sin(a), 0.95),
      }));
      t += 300;
    }
  }
  return frames;
}

void main() {
  late _FakeKeyframes keyframes;
  late _FakeApi api;
  late ExecutionAnalysisController controller;

  setUp(() {
    keyframes = _FakeKeyframes();
    api = _FakeApi();
    controller = ExecutionAnalysisController(ruleSets: _FileRuleSets(), keyframes: keyframes, api: api);
  });

  Future<void> analyze(List<PoseFrame> frames) => controller.analyze(
        exerciseKey: 'squat',
        exerciseName: 'Agachamento livre',
        recorded: RecordedSet(videoPath: '/tmp/x.mp4', frames: frames),
        language: 'pt',
      );

  test('should_end_in_no_reps_without_calling_the_backend', () async {
    await analyze(const []);
    expect(controller.state.phase, ExecutionPhase.noReps);
    expect(api.sentReport, isNull);
  });

  test('should_show_measured_result_and_then_the_ai_feedback', () async {
    api.response = const ExecutionFeedback(feedback: 'Boa! Desça controlando.', confirmedIssueIds: ['tempo']);
    await analyze(_squats(3));

    final state = controller.state;
    expect(state.phase, ExecutionPhase.result);
    expect(state.report!.repCount, 3);
    expect(state.feedback!.feedback, 'Boa! Desça controlando.');
    expect(state.feedbackLoading, isFalse);
    expect(state.feedbackFailed, isFalse);
    expect(api.sentKeyframes, keyframes.requested.length);
    expect(api.sentKeyframes, inInclusiveRange(1, maxKeyframes));
  });

  test('should_fall_back_to_local_cues_when_the_backend_fails', () async {
    api.error = DioException(requestOptions: RequestOptions(path: '/app/execution-analysis'));
    await analyze(_squats(2, bottom: 110));

    final state = controller.state;
    expect(state.phase, ExecutionPhase.result);
    expect(state.feedbackFailed, isTrue);
    expect(state.report!.issues.map((i) => i.id), contains('depth'));
  });

  group('frameAt', () {
    final frames = [for (final t in [0, 100, 200, 300]) PoseFrame(t, const {})];

    test('should_return_the_nearest_frame', () {
      expect(frameAt(frames, 140)!.tMs, 100);
      expect(frameAt(frames, 160)!.tMs, 200);
      expect(frameAt(frames, 999)!.tMs, 300);
      expect(frameAt(frames, -5)!.tMs, 0);
      expect(frameAt(const [], 10), isNull);
    });
  });

  testWidgets('skeleton_painter_should_paint_without_errors', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(
        size: const Size(300, 500),
        painter: SkeletonOverlayPainter(
          frame: _squats(1)[3],
          side: BodySide.right,
          alertJoints: const {Joint.knee, Joint.hip},
          annotation: const AngleAnnotation(vertex: Joint.knee, fixedArm: Joint.ankle, movingArm: Joint.hip, target: 95),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
