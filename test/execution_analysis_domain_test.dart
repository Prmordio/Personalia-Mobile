import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/execution_analysis/domain/exercise_rule_set.dart';
import 'package:personalia_app/features/execution_analysis/domain/execution_rule_catalog.dart';
import 'package:personalia_app/features/execution_analysis/domain/geometry.dart';
import 'package:personalia_app/features/execution_analysis/domain/keyframe_selector.dart';
import 'package:personalia_app/features/execution_analysis/domain/pose_frame.dart';
import 'package:personalia_app/features/execution_analysis/domain/rep_segmenter.dart';
import 'package:personalia_app/features/execution_analysis/domain/rule_engine.dart';
import 'package:personalia_app/features/execution_analysis/domain/signals.dart';

/// Parâmetros de uma rep sintética de agachamento vista do lado direito.
class _RepSpec {
  const _RepSpec({
    this.bottomKnee = 85,
    this.trunkLean = 30,
    this.durationMs = 2400,
    this.glimpse = false,
    this.hidden = false,
  });
  final double bottomKnee;
  final double trunkLean;
  final int durationMs;

  /// Corpo visível só de relance perto do fundo (oclusão na maior parte da rep).
  final bool glimpse;

  /// Corpo fora do quadro durante toda a rep.
  final bool hidden;

  bool visibleAt(double p) {
    if (hidden) return p <= 0.05 || p >= 0.95;
    if (glimpse) return p <= 0.05 || p >= 0.95 || (p > 0.42 && p < 0.58);
    return true;
  }
}

const _fps = 15;
const _topKnee = 175.0;
const _pauseMs = 500;

PosePoint _p(double x, double y, [double c = 0.95]) => PosePoint(x, y, c);

/// Monta um quadro com ângulo do joelho [knee] e inclinação do tronco [trunk] (graus).
PoseFrame _frame(int tMs, double knee, double trunk, {double confidence = 0.95}) {
  double rad(double d) => d * math.pi / 180;
  const ankle = (x: 0.5, y: 0.9);
  final shinLean = rad((180 - knee) / 3);
  final kx = ankle.x + 0.22 * math.sin(shinLean), ky = ankle.y - 0.22 * math.cos(shinLean);
  // coxa = canela (joelho→tornozelo) girada por `knee` graus, para trás (x menor).
  final ux = ankle.x - kx, uy = ankle.y - ky;
  final a = rad(knee);
  final tx = ux * math.cos(a) + uy * math.sin(a), ty = -ux * math.sin(a) + uy * math.cos(a);
  final hx = kx + tx, hy = ky + ty;
  final sx = hx + 0.3 * math.sin(rad(trunk)), sy = hy - 0.3 * math.cos(rad(trunk));
  final c = confidence;
  return PoseFrame(tMs, {
    Landmark.rightShoulder: _p(sx, sy, c),
    Landmark.rightHip: _p(hx, hy, c),
    Landmark.rightKnee: _p(kx, ky, c),
    Landmark.rightAnkle: _p(ankle.x, ankle.y, c),
    Landmark.rightHeel: _p(ankle.x - 0.03, ankle.y + 0.02, c),
    Landmark.rightFootIndex: _p(ankle.x + 0.06, ankle.y + 0.02, c),
    Landmark.leftHip: _p(hx, hy, 0.2),
    Landmark.leftKnee: _p(kx, ky, 0.2),
  });
}

List<PoseFrame> _set(List<_RepSpec> reps, {double noise = 0}) {
  final rnd = math.Random(7);
  final frames = <PoseFrame>[];
  var t = 0;
  const step = 1000 ~/ _fps;
  void add(double knee, double trunk, {double confidence = 0.95}) {
    frames.add(_frame(t, knee + (rnd.nextDouble() * 2 - 1) * noise, trunk, confidence: confidence));
    t += step;
  }

  for (var i = 0; i < _pauseMs ~/ step; i++) {
    add(_topKnee, 10);
  }
  for (final rep in reps) {
    for (var e = 0; e < rep.durationMs; e += step) {
      final p = e / rep.durationMs;
      final depth = (1 - math.cos(2 * math.pi * p)) / 2;
      add(
        _topKnee - (_topKnee - rep.bottomKnee) * depth,
        10 + (rep.trunkLean - 10) * depth,
        confidence: rep.visibleAt(p) ? 0.95 : 0.1,
      );
    }
    for (var i = 0; i < _pauseMs ~/ step; i++) {
      add(_topKnee, 10);
    }
  }
  return frames;
}

ExerciseRuleSet _squatRules() => ExerciseRuleSet.fromJson(
      jsonDecode(File('test/fixtures/execution_rules/squat.json').readAsStringSync()) as Map<String, dynamic>,
    );

void main() {
  group('geometry', () {
    test('should_measure_right_angle_at_vertex', () {
      expect(angleAt(_p(0, 1), _p(0, 0), _p(1, 0)), closeTo(90, 0.001));
    });

    test('should_measure_lean_from_vertical', () {
      expect(angleFromVertical(_p(0.5, 0), _p(0.5, 1)), closeTo(0, 0.001));
      expect(angleFromVertical(_p(1, 0), _p(0, 1)), closeTo(45, 0.001));
    });

    test('synthetic_frame_should_have_requested_knee_angle_and_trunk_lean', () {
      final f = _frame(0, 100, 40);
      final knee = angleAt(f.points[Landmark.rightHip]!, f.points[Landmark.rightKnee]!, f.points[Landmark.rightAnkle]!);
      expect(knee, closeTo(100, 0.01));
      expect(angleFromVertical(f.points[Landmark.rightShoulder]!, f.points[Landmark.rightHip]!), closeTo(40, 0.01));
    });

    test('should_pick_the_most_visible_side', () {
      expect(pickVisibleSide([_frame(0, 170, 10)]), BodySide.right);
    });
  });

  group('RepSegmenter', () {
    final rules = _squatRules();

    List<Rep> segment(List<PoseFrame> frames) => RepSegmenter(rules.rep).segment(
          extractSignals(frames, BodySide.right, {'knee_angle'}, minConfidence: 0.5),
        );

    test('should_count_each_rep', () {
      expect(segment(_set(List.filled(10, const _RepSpec()))), hasLength(10));
    });

    test('should_not_create_extra_reps_from_noise', () {
      expect(segment(_set(List.filled(5, const _RepSpec()), noise: 5)), hasLength(5));
    });

    test('should_ignore_shallow_movements_that_do_not_cross_the_down_threshold', () {
      expect(segment(_set(const [_RepSpec(bottomKnee: 140)])), isEmpty);
    });

    test('should_measure_bottom_and_phases', () {
      final rep = segment(_set(const [_RepSpec(bottomKnee: 90, durationMs: 3000)])).single;
      expect(rep.bottomValue, closeTo(90, 4));
      expect(rep.eccentricMs, greaterThan(800));
      expect(rep.concentricMs, greaterThan(800));
    });
  });

  group('RuleEngine', () {
    final engine = RuleEngine(_squatRules());

    test('should_report_no_issues_for_a_clean_set', () {
      final report = engine.evaluate(_set(List.filled(6, const _RepSpec())));
      expect(report.repCount, 6);
      expect(report.issues, isEmpty);
      expect(report.score, 100);
      expect(report.side, BodySide.right);
    });

    test('should_flag_shallow_reps_and_fatigue_on_the_last_reps', () {
      final report = engine.evaluate(_set([
        ...List.filled(6, const _RepSpec(bottomKnee: 82)),
        ...List.filled(4, const _RepSpec(bottomKnee: 108)),
      ]));
      final depth = report.issues.singleWhere((i) => i.id == 'depth');
      expect(depth.reps, [7, 8, 9, 10]);
      expect(depth.measured, closeTo(108, 4));
      expect(report.fatigue, isNotNull);
      expect(report.fatigue!.fromRep, 7);
      expect(report.score, lessThan(100));
    });

    test('should_flag_excessive_trunk_lean', () {
      final report = engine.evaluate(_set(const [_RepSpec(), _RepSpec(trunkLean: 60)]));
      expect(report.issues.singleWhere((i) => i.id == 'trunk_lean').reps, [2]);
    });

    test('should_flag_fast_descent', () {
      final report = engine.evaluate(_set(const [_RepSpec(durationMs: 1000)]));
      expect(report.issues.map((i) => i.id), contains('tempo'));
    });

    test('should_not_accuse_errors_on_reps_seen_only_briefly', () {
      final report = engine.evaluate(_set(const [_RepSpec(), _RepSpec(bottomKnee: 110, glimpse: true), _RepSpec()]));
      expect(report.repCount, 3);
      expect(report.unclearReps, [2]);
      expect(report.issues, isEmpty);
    });

    test('should_not_count_reps_performed_out_of_frame', () {
      final report = engine.evaluate(_set(const [_RepSpec(), _RepSpec(bottomKnee: 110, hidden: true), _RepSpec()]));
      expect(report.repCount, 2);
      expect(report.issues, isEmpty);
    });

    test('should_tolerate_values_just_past_the_target', () {
      final report = engine.evaluate(_set(const [_RepSpec(bottomKnee: 96), _RepSpec(bottomKnee: 105)]));
      expect(report.issues.singleWhere((i) => i.id == 'depth').reps, [2]);
    });

    test('should_serialize_the_fields_the_backend_validates', () {
      final json = engine.evaluate(_set(const [_RepSpec(bottomKnee: 105)])).toJson();
      expect(json['exercise'], 'squat');
      expect(json['ruleSetVersion'], '2');
      expect(json['score'], isA<int>());
      expect(json['repCount'], 1);
      expect(json['issues'], isA<List>());
      expect(jsonEncode(json), isNot(contains('"p"')), reason: 'pose bruta não vai pro backend');
    });
  });

  group('selectKeyframes', () {
    final engine = RuleEngine(_squatRules());

    test('should_include_the_worst_moment_of_each_issue_and_respect_the_limit', () {
      final report = engine.evaluate(_set([
        ...List.filled(8, const _RepSpec(bottomKnee: 82)),
        ...List.filled(8, const _RepSpec(bottomKnee: 110, trunkLean: 60)),
      ]));
      final picks = selectKeyframes(report);
      expect(picks.length, lessThanOrEqualTo(maxKeyframes));
      final worstDepth = report.issues.singleWhere((i) => i.id == 'depth').worst;
      expect(picks.map((p) => p.tMs), contains(worstDepth.tMs));
      expect(picks.any((p) => p.label.contains('trunk_lean')), isTrue);
      expect(picks.map((p) => p.tMs).toList(), orderedEquals([...picks.map((p) => p.tMs)]..sort()));
    });

    test('should_return_nothing_without_reps', () {
      expect(selectKeyframes(engine.evaluate(_set(const []))), isEmpty);
    });
  });

  group('RuleCheck', () {
    RuleCheck check(CheckOp op, {double tolerance = 0}) => RuleCheck(
          id: 'x',
          signal: 'knee_angle',
          agg: Aggregation.min,
          op: op,
          target: 95,
          tolerance: tolerance,
          unit: 'deg',
          severity: IssueSeverity.medium,
          weight: 10,
          joints: const [],
          cue: const {'pt': ''},
        );

    test('should_pass_within_tolerance_and_fail_beyond_it', () {
      expect(check(CheckOp.lte, tolerance: 3).passes(97.9), isTrue);
      expect(check(CheckOp.lte, tolerance: 3).passes(98.1), isFalse);
      expect(check(CheckOp.gte, tolerance: 3).passes(92.1), isTrue);
      expect(check(CheckOp.gte, tolerance: 3).passes(91.9), isFalse);
    });

    test('should_be_strict_without_tolerance', () {
      expect(check(CheckOp.lte).passes(95), isTrue);
      expect(check(CheckOp.lte).passes(95.1), isFalse);
    });
  });

  group('ExecutionRuleCatalog', () {
    ExerciseRuleSet withNames(List<String> names, {int schemaVersion = 1, String signal = 'knee_angle'}) {
      final json = jsonDecode(File('test/fixtures/execution_rules/squat.json').readAsStringSync()) as Map<String, dynamic>;
      json['exerciseNames'] = names;
      json['schemaVersion'] = schemaVersion;
      (json['checks'] as List).first['signal'] = signal;
      return ExerciseRuleSet.fromJson(json);
    }

    test('should_match_only_names_linked_in_the_panel_ignoring_case_accents_and_spaces', () {
      final catalog = ExecutionRuleCatalog([withNames(['agachamento livre com barra'])]);
      expect(catalog.match('Agachamento  LIVRE com Barra '), 'squat');
      expect(catalog.match('Agachamento livre'), isNull, reason: 'nome parecido mas não ligado');
      expect(catalog.ruleSet('squat')!.checks.first.labelFor('en'), 'Depth');
    });

    test('should_ignore_rule_sets_this_app_version_cannot_apply', () {
      expect(ExecutionRuleCatalog([withNames(['agachamento'], schemaVersion: 2)]).isEmpty, isTrue);
      expect(ExecutionRuleCatalog([withNames(['agachamento'], signal: 'wrist_flick')]).isEmpty, isTrue);
    });

    test('should_drop_only_the_rule_set_this_app_cannot_parse', () {
      final good = jsonDecode(File('test/fixtures/execution_rules/squat.json').readAsStringSync()) as Map<String, dynamic>;
      final future = jsonDecode(jsonEncode(good)) as Map<String, dynamic>
        ..['exercise'] = 'future'
        ..['exerciseNames'] = ['futuro'];
      (future['checks'] as List).first['joints'] = ['tail'];
      final catalog = ExecutionRuleCatalog.fromJson({
        'ruleSets': [future, good..['exerciseNames'] = ['agachamento']],
      });
      expect(catalog.match('agachamento'), 'squat');
      expect(catalog.ruleSet('future'), isNull);
    });

    test('should_normalize_like_the_trainer', () {
      expect(normalizeExerciseName('  Sentadilla   Búlgara Peña '), 'sentadilla bulgara pena');
    });
  });

  group('Membros superiores', () {
    /// Braço do lado direito: [shoulder] = ângulo quadril-ombro-cotovelo, [elbow] =
    /// ombro-cotovelo-punho. Pernas fora do quadro (supino/rosca na máquina).
    PoseFrame armFrame(int tMs, {required double elbow, double shoulder = 10}) {
      double rad(double d) => d * math.pi / 180;
      const s = (x: 0.5, y: 0.3);
      final e = (x: s.x + 0.15 * math.sin(rad(shoulder)), y: s.y + 0.15 * math.cos(rad(shoulder)));
      // punho = direção cotovelo→ombro girada por `elbow` graus.
      final dx = (s.x - e.x) / 0.15, dy = (s.y - e.y) / 0.15;
      final a = rad(elbow);
      final w = (x: e.x + 0.13 * (dx * math.cos(a) - dy * math.sin(a)), y: e.y + 0.13 * (dx * math.sin(a) + dy * math.cos(a)));
      return PoseFrame(tMs, {
        Landmark.rightShoulder: _p(s.x, s.y),
        Landmark.rightElbow: _p(e.x, e.y),
        Landmark.rightWrist: _p(w.x, w.y),
        Landmark.rightHip: _p(0.5, 0.6),
        Landmark.leftShoulder: _p(0.5, 0.3, 0.2),
        Landmark.leftHip: _p(0.5, 0.6, 0.2),
      });
    }

    /// Tríceps na polia: cotovelo dobrado (80°) → estendido ([peak]) → volta.
    List<PoseFrame> pushdowns(int reps, {double peak = 170}) {
      final frames = <PoseFrame>[];
      var t = 0;
      for (var r = 0; r < reps; r++) {
        for (var i = 0; i <= 30; i++) {
          final elbow = 80 + (peak - 80) * math.sin(math.pi * i / 30);
          frames.add(armFrame(t, elbow: elbow));
          t += 1000 ~/ _fps;
        }
      }
      return frames;
    }

    RuleCheck lockout() => RuleCheck(
          id: 'lockout',
          signal: 'elbow_angle',
          agg: Aggregation.max,
          op: CheckOp.gte,
          target: 165,
          unit: 'deg',
          severity: IssueSeverity.medium,
          weight: 60,
          joints: const [Joint.elbow],
          cue: const {'pt': 'Estenda o cotovelo.'},
        );

    final pushdown = ExerciseRuleSet(
      exercise: 'triceps_pushdown',
      version: '1',
      minConfidence: 0.5,
      rep: const RepRule(signal: 'elbow_angle', down: 150, up: 100, minDurationMs: 500),
      checks: [lockout()],
    );

    test('should_measure_elbow_and_shoulder_angles', () {
      final f = armFrame(0, elbow: 90, shoulder: 40);
      final samples = extractSignals([f], BodySide.right, {'elbow_angle', 'shoulder_angle'}, minConfidence: 0.5);
      expect(samples.single['elbow_angle'], closeTo(90, 0.01));
      expect(samples.single['shoulder_angle'], closeTo(40, 0.01));
    });

    test('should_count_reps_of_a_rising_signal_when_down_is_greater_than_up', () {
      expect(pushdown.rep.rising, isTrue);
      final reps = RepSegmenter(pushdown.rep).segment(
        extractSignals(pushdowns(5), BodySide.right, {'elbow_angle'}, minConfidence: 0.5),
      );
      expect(reps, hasLength(5), reason: 'começa em repouso (≤ up), então a primeira rep já conta');
      expect(reps.first.bottomValue, closeTo(170, 4), reason: 'o "fundo" de um sinal que sobe é o pico');
      expect(reps.first.topValue, lessThan(100));
    });

    test('should_track_only_the_joints_the_rule_measures', () {
      expect(trackedJoints(pushdown), [Joint.shoulder, Joint.elbow, Joint.wrist]);
      expect(trackedJoints(_squatRules()), containsAll([Joint.hip, Joint.knee, Joint.ankle, Joint.heel]));
    });

    test('should_evaluate_an_arm_exercise_without_legs_in_frame', () {
      final report = RuleEngine(pushdown).evaluate(pushdowns(5, peak: 156));
      expect(report.side, BodySide.right);
      expect(report.repCount, 5);
      expect(report.issues.single.id, 'lockout');
    });

    test('should_read_the_camera_view_and_report_it', () {
      final json = jsonDecode(File('test/fixtures/execution_rules/squat.json').readAsStringSync()) as Map<String, dynamic>;
      expect(ExerciseRuleSet.fromJson(json).view, CameraView.side);
      final front = ExerciseRuleSet.fromJson(json..['view'] = 'front');
      expect(front.view, CameraView.front);
      expect(RuleEngine(front).evaluate(_set(const [_RepSpec()])).toJson()['view'], 'front');
    });
  });
}
