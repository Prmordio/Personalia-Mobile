import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/workout/state/workout_live_activity.dart';

WorkoutLiveState initial({int sets = 4, int rest = 60}) => WorkoutLiveState({
  'flowVersion': 2,
  'weights': {'Supino': '20', 'Remada': '20'},
  'id': 'session-1',
  'date': DateTime.now().toIso8601String().substring(0, 10),
  'day': 'Treino A',
  'exercises': [
    {'name': 'Supino', 'sets': sets, 'reps': '12', 'restSeconds': rest},
    {'name': 'Remada', 'sets': 3, 'reps': '10–12', 'restSeconds': 90},
  ],
  'completed': [0, 0],
  'index': 0,
  'phase': 'ready',
  'running': false,
  'seconds': 0,
  'anchor': 0,
  'revision': 0,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'next exercise requires weight and clearing it blocks advancement again',
    () {
      var s = initial(sets: 1).act('rest', now: 0).resolveAt(60000);
      s.data['weights'] = <String, String>{};
      expect(s.act('next', now: 61000).index, 0);
      expect(s.exerciseFinished(0), isFalse);
      s.data['weights'] = {'Supino': '20'};
      expect(s.act('next', now: 62000).index, 1);
      s.data['weights'] = {'Supino': '  '};
      expect(s.act('next', now: 63000).index, 0);
    },
  );

  test(
    'rest records the performed series once and never starts a stopwatch',
    () {
      final s = initial().act('rest', now: 1000);
      expect(s.phase, 'rest');
      expect(s.running, true);
      expect(s.data['seconds'], 60);
      expect(s.completed, 1);
      expect(s.currentSet, 1);
      expect(s.act('rest', now: 2000).completed, 1);
      expect(s.act('rest', now: 2000).data['anchor'], 1000);
    },
  );
  test('zero stops rest and offers the rest button for the next series', () {
    final resting = initial().act('rest', now: 1000);
    expect(resting.resolveAt(60999).phase, 'rest');
    final finished = resting.resolveAt(61000);
    expect(finished.phase, 'ready');
    expect(finished.running, false);
    expect(finished.seconds, 0);
    expect(finished.completed, 1);
    expect(finished.currentSet, 2);
    expect(
      finished.resolveAt(180000).data['revision'],
      finished.data['revision'],
    );
    final next = finished.act('rest', now: 180000);
    expect(next.phase, 'rest');
    expect(next.completed, 2);
    expect(next.data['seconds'], 60);
  });
  test('pause, resume and adding time preserve the series count', () {
    var s = initial().act('rest', now: 1000).act('toggle', now: 11000);
    expect(s.running, false);
    expect(s.data['seconds'], 50);
    s = s.act('toggle', now: 21000).act('add', now: 31000);
    expect(s.running, true);
    expect(s.data['seconds'], 70);
    expect(s.completed, 1);
  });
  test('last rest ends the exercise and next exercise waits for rest', () {
    var s = initial(sets: 2).act('rest', now: 0).resolveAt(60000);
    s = s.act('rest', now: 61000);
    expect(s.phase, 'rest');
    expect(s.completed, 2);
    s = s.resolveAt(121000);
    expect(s.phase, 'done');
    expect(s.running, false);
    s = s.act('next', now: 122000);
    expect(s.name, 'Remada');
    expect(s.phase, 'ready');
    expect(s.running, false);
    expect(s.seconds, 0);
    expect(s.data['completed'], [2, 0]);
  });
  test(
    'exercise finalization waits for the final rest and survives moving on',
    () {
      var live = initial(sets: 1).act('rest', now: 0);
      expect(live.exerciseFinished(0), isFalse);
      live = live.resolveAt(60000);
      expect(live.exerciseFinished(0), isTrue);
      expect(live.exerciseFinished(1), isFalse);
      live = live.act('next', now: 61000);
      expect(live.exerciseFinished(0), isTrue);
      expect(live.exerciseFinished(1), isFalse);
    },
  );
  test('zero rest and skipping advance once without an execution clock', () {
    final noRest = initial(rest: 0).act('rest', now: 0);
    expect(noRest.phase, 'ready');
    expect(noRest.running, false);
    expect(noRest.completed, 1);
    final skipped = initial().act('rest', now: 1000).act('skip', now: 2000);
    expect(skipped.phase, 'ready');
    expect(skipped.completed, 1);
    expect(skipped.seconds, 0);
  });
  test('legacy stopwatch migrates while preserving crossed-off series', () {
    final legacy = initial().data..remove('flowVersion');
    legacy['phase'] = 'exercise';
    legacy['running'] = true;
    legacy['seconds'] = 400;
    legacy['completed'] = [2, 0];
    final migrated = WorkoutLiveState(legacy).resolveAt(10000);
    expect(migrated.phase, 'ready');
    expect(migrated.running, false);
    expect(migrated.seconds, 0);
    expect(migrated.completed, 2);
    final rest = migrated.act('rest', now: 20000);
    expect(rest.completed, 3);
    expect(rest.data['seconds'], 60);
  });
  test('legacy awaiting rest does not count the same series twice', () {
    final legacy = initial().data..remove('flowVersion');
    legacy['phase'] = 'awaitRest';
    legacy['completed'] = [2, 0];
    final migrated = WorkoutLiveState(legacy).resolveAt(10000);
    expect(migrated.currentSet, 2);
    final rest = migrated.act('rest', now: 20000);
    expect(rest.phase, 'rest');
    expect(rest.completed, 2);
    expect(rest.resolveAt(80000).currentSet, 3);
  });
  test('old execution commands never start a stopwatch or record a series', () {
    final s = initial();
    expect(s.act('start', now: 0).phase, 'ready');
    expect(s.act('complete', now: 0).completed, 0);
    expect(s.act('start', now: 0).running, false);
  });
  test(
    'controller restores a background rest without replacing progress',
    () async {
      var native = initial();
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(WorkoutLiveController.channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'action') {
          final args = call.arguments as Map;
          expect(args['revision'], native.data['revision']);
          native = native.act(args['action'] as String);
        }
        return jsonEncode(native.data);
      });
      final controller = WorkoutLiveController();
      try {
        await controller.refresh();
        native = native.act('rest');
        await controller.refresh();
        expect(controller.state!.phase, 'rest');
        expect(controller.state!.completed, 1);
        await controller.prepare(
          day: 'Treino A',
          exercises: List<Map<String, dynamic>>.from(native.exercises),
        );
        expect(calls.where((c) => c.method == 'prepare'), isEmpty);
        await controller.action('toggle');
        expect(controller.state!.running, false);
        expect(controller.state!.completed, 1);
      } finally {
        controller.dispose();
        messenger.setMockMethodCallHandler(WorkoutLiveController.channel, null);
      }
    },
  );
}
