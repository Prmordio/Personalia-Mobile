import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/workout/state/workout_live_activity.dart';
import 'package:personalia_app/features/workout/state/active_workout_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native first rest keeps its start through expiry, next rests and restoration',
    () {
      final start = DateTime(2026, 10, 16, 8);
      var live = WorkoutLiveState({
        'flowVersion': 2,
        'id': 'session',
        'date': '2026-10-16',
        'day': 'Treino A',
        'exercises': [
          {'name': 'Supino', 'sets': 3, 'reps': '10', 'restSeconds': 60},
        ],
        'index': 0,
        'completed': [0],
        'phase': 'ready',
        'running': false,
        'seconds': 0,
        'anchor': 0,
        'revision': 0,
      });
      expect(live.startedAt, isNull);
      live = live.act('rest', now: start.millisecondsSinceEpoch);
      live = live.resolveAt(
        start.add(const Duration(minutes: 2)).millisecondsSinceEpoch,
      );
      expect(live.phase, 'ready');
      final resumedAt = start.add(const Duration(minutes: 15));
      final restored = live.restoreSession(null, now: resumedAt)!;
      expect(restored.startedAt, start);
      expect(
        resumedAt.difference(restored.startedAt),
        const Duration(minutes: 15),
      );
      live = live.act('rest', now: resumedAt.millisecondsSinceEpoch);
      expect(live.startedAt, start);
      final earlier = ActiveWorkoutSession(
        dayName: 'Treino A',
        startedAt: start.subtract(const Duration(minutes: 1)),
      );
      expect(
        identical(live.restoreSession(earlier, now: resumedAt), earlier),
        isTrue,
      );
    },
  );

  test(
    'editing a completed exercise outside the current queue must preserve active rest',
    () async {
      final activeExercise = <String, dynamic>{
        'name': 'Remada',
        'sets': 3,
        'reps': '12',
        'restSeconds': 90,
      };
      final completedExercise = <String, dynamic>{
        'name': 'Supino',
        'sets': 3,
        'reps': '10',
        'restSeconds': 60,
      };
      var native = <String, dynamic>{
        'flowVersion': 2,
        'id': 'active-rest',
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'day': 'Treino A',
        'exercises': [activeExercise],
        'index': 0,
        'completed': [1],
        'phase': 'rest',
        'running': true,
        'seconds': 90,
        'anchor': DateTime.now().millisecondsSinceEpoch,
        'revision': 2,
        'startedAt': DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch,
      };
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(WorkoutLiveController.channel, (
        MethodCall call,
      ) async {
        if (call.method == 'prepare') {
          native =
              jsonDecode((call.arguments as Map)['json'] as String)
                  as Map<String, dynamic>;
        }
        return jsonEncode(native);
      });
      final controller = WorkoutLiveController();
      try {
        await controller.refresh();
        await controller.prepare(
          day: 'Treino A',
          exercises: [completedExercise, activeExercise],
          completed: [3, 1],
        );
        expect(
          native['id'],
          'active-rest',
          reason:
              'Editing weight must not replace the session or cancel the rest.',
        );
        expect(native['phase'], 'rest');
        expect(native['running'], true);
        final originalStart = native['startedAt'];
        final originalAnchor = native['anchor'];
        await controller.prepare(
          day: 'Treino A',
          exercises: [completedExercise, activeExercise],
          completed: [1, 1],
          recordOnly: true,
        );
        expect(native['id'], 'active-rest');
        expect(native['anchor'], originalAnchor);
        // Selecting another exercise keeps the original workout start, even
        // when the caller's in-memory session was recreated later.
        await controller.prepare(
          day: 'Treino A',
          exercises: [completedExercise],
          completed: [0],
          startedAt: DateTime.now(),
        );
        expect(native['startedAt'], originalStart);
      } finally {
        controller.dispose();
        messenger.setMockMethodCallHandler(WorkoutLiveController.channel, null);
      }
    },
  );
}
