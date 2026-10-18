import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/home/state/today_workout_override.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/workout/state/workout_session_cache.dart';
import 'package:personalia_app/features/workout/presentation/rest_timer_screen.dart';

class MemoryStore implements WorkoutCacheStore {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk unavailable');
    values[key] = value;
  }
}

String token(String user) =>
    'x.${base64Url.encode(utf8.encode(jsonEncode({'sub': user})))}.x';
final plan = [
  {'nome': 'Supino', 'series': '3', 'repeticoes': '10', 'descanso': '60s'},
  {'nome': 'Remada', 'series': '3', 'repeticoes': '12', 'descanso': '90s'},
];
Map<String, dynamic> record(
  String weight, {
  bool finished = true,
  String observation = 'last set',
}) => {
  'remaining': 0,
  'completedSets': 3,
  'weight': weight,
  'observation': observation,
  'running': false,
  'finished': finished,
  'elapsed': 0,
};
Map<String, dynamic> payload() => {
  'dayName': 'Treino A',
  'startedAt': '2026-10-16T08:00:00.000',
  'endedAt': '2026-10-16T09:00:00.000',
  'mood': 'ok',
  'feedback': 'good session',
  'exercises': [
    {'name': 'Supino', 'weight': '20', 'observation': 'last set'},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'stages start immediately and keeps acknowledged active records until completion',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      expect(cache.startedAt, isNotNull);
      final requests = <Map<String, dynamic>>[];
      await cache.sync((p) async => requests.add(p));
      expect(requests.map((p) => p['_action']), ['start']);
      expect(requests.single['startedAt'], endsWith('Z'));
      expect(cache.activeId, id);
      cache.capture(('Supino', 60, 3), record('', finished: false));
      await cache.sync((p) async => requests.add(p));
      expect(requests.length, 1);
      cache.capture(('Supino', 60, 3), record('20'));
      await cache.sync((p) async => requests.add(p));
      expect(requests.last['_action'], 'exercise');
      final log = requests.last['logId'];
      expect(cache.record(('Supino', 60, 3))!['weight'], '20');
      cache.capture(('Supino', 60, 3), record('25'));
      await cache.sync((p) async => requests.add(p));
      expect(requests.last['logId'], log);
      expect(requests.last['weight'], '25');
      cache.capture(('Supino', 60, 3), record('', finished: false));
      await cache.sync((p) async => requests.add(p));
      expect(requests.last['_action'], 'removeExercise');
      expect(requests.last['logId'], log);
      await cache.stage(id, payload());
      await cache.sync((p) async => requests.add(p));
      expect(requests.last['_action'], 'finish');
      expect(requests.last['feedback'], 'good session');
      expect(requests.last.containsKey('exercises'), isFalse);
      expect(requests.last.containsKey('totalCount'), isFalse);
      expect(cache.lastCompletion!['exercises'], isNotEmpty);
      expect(cache.active, isNull);
      expect(cache.pendingCount, 0);
      final saved = jsonDecode(store.values.values.single) as Map;
      expect(saved['drafts'], isEmpty);
    },
  );

  test(
    'failed exercise blocks finalization, restart preserves ordering and stable IDs',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      cache.capture(('Supino', 60, 3), record('20'));
      await cache.stage(id, payload());
      final first = <Map<String, dynamic>>[];
      await expectLater(
        cache.sync((p) async {
          first.add(p);
          if (p['_action'] == 'exercise') throw StateError('offline');
        }),
        throwsStateError,
      );
      expect(first.map((p) => p['_action']), ['start', 'exercise']);
      final restored = WorkoutSessionCache(store, () async => token('a'));
      final retry = <Map<String, dynamic>>[];
      await restored.sync((p) async => retry.add(p));
      expect(retry.map((p) => p['_action']), ['exercise', 'finish']);
      expect(retry.first['logId'], first.last['logId']);
      expect(restored.isPending(id), isFalse);
    },
  );

  test(
    'cancellation stays durable while offline and removes the draft only after server ACK',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      cache.capture(('Supino', 60, 3), record('20'));
      await cache.cancel();
      expect(cache.active, isNull);
      await expectLater(
        cache.sync((_) async => throw StateError('offline')),
        throwsStateError,
      );
      expect(cache.isPending(id), isTrue);
      final data = jsonDecode(store.values.values.single) as Map;
      expect(data['drafts'][id]['status'], 'cancelled');
      final restored = WorkoutSessionCache(store, () async => token('a'));
      final actions = <String>[];
      await restored.sync((p) async => actions.add(p['_action'] as String));
      expect(actions, ['start', 'cancel']);
      expect(restored.isPending(id), isFalse);
    },
  );

  test('sync drains edits added while a previous write is in flight', () async {
    final store = MemoryStore();
    final cache = WorkoutSessionCache(store, () async => token('a'));
    await cache.open('Treino A', plan);
    final entered = Completer<void>();
    final release = Completer<void>();
    final actions = <String>[];
    final sync = cache.sync((p) async {
      actions.add(p['_action'] as String);
      if (p['_action'] == 'start') {
        entered.complete();
        await release.future;
      }
    });
    await entered.future;
    cache.capture(('Supino', 60, 3), record('20'));
    release.complete();
    await sync;
    expect(actions, ['start', 'exercise']);
  });

  test('cancel can proceed when the current exercise write fails', () async {
    final cache = WorkoutSessionCache(MemoryStore(), () async => token('a'));
    await cache.open('Treino A', plan);
    cache.capture(('Supino', 60, 3), record('20'));
    final entered = Completer<void>();
    final release = Completer<void>();
    final actions = <String>[];
    final sync = cache.sync((p) async {
      actions.add(p['_action'] as String);
      if (p['_action'] == 'exercise') {
        entered.complete();
        await release.future;
        throw StateError('response lost');
      }
    });
    await entered.future;
    await cache.cancel();
    release.complete();
    await sync;
    expect(actions, ['start', 'exercise', 'cancel']);
    expect(cache.pendingCount, 0);
  });

  test(
    'repeated cancellation after disk failure still waits for a durable write',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      store.fail = true;
      await expectLater(cache.cancel(), throwsStateError);
      await expectLater(cache.cancel(), throwsStateError);
      store.fail = false;
      await cache.cancel();
      final restored = WorkoutSessionCache(store, () async => token('a'));
      await restored.bind();
      expect(restored.active, isNull);
      expect(restored.isPending(id), isTrue);
      final actions = <String>[];
      await restored.sync((p) async => actions.add(p['_action'] as String));
      expect(actions, ['start', 'cancel']);
    },
  );

  test(
    'cancelled exercise cannot be resurrected by a stale native queue',
    () async {
      final cache = WorkoutSessionCache(MemoryStore(), () async => token('a'));
      await cache.open('Treino A', plan);
      cache.capture(('Supino', 60, 3), record('20'));
      await cache.ignoreNative('Supino');
      cache.capture(('Supino', 60, 3), record('', finished: false));
      cache.mergeNative({
        'day': 'Treino A',
        'exercises': [
          {'name': 'Supino', 'restSeconds': 60, 'sets': 3},
        ],
        'completed': [3],
        'index': 0,
        'phase': 'done',
        'weights': {'Supino': '20'},
      });
      expect(cache.record(('Supino', 60, 3))!['finished'], isFalse);
      expect(cache.record(('Supino', 60, 3))!['weight'], '');
    },
  );

  test(
    'a corrupt cache in another account cannot expose the previous session',
    () async {
      final store = MemoryStore();
      var user = 'a';
      final cache = WorkoutSessionCache(store, () async => token(user));
      await cache.open('Treino A', plan);
      store.values['workout_sessions_v1_b'] = 'invalid json';
      user = 'b';
      await expectLater(cache.bind(), throwsFormatException);
      expect(cache.active, isNull);
      expect(cache.owner, isNull);
      user = 'a';
      await cache.bind();
      expect(cache.active!['day'], 'Treino A');
    },
  );

  test(
    'an unfinished cached plan can be resumed with the backend offline',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final container = ProviderContainer(
        overrides: [
          workoutSessionCacheProvider.overrideWithValue(cache),
          todayWorkoutProvider.overrideWith(
            (ref) async => throw StateError('offline'),
          ),
          currentWorkoutProvider.overrideWith(
            (ref) async => throw StateError('offline'),
          ),
        ],
      );
      try {
        final today = await container.read(
          effectiveTodayWorkoutProvider.future,
        );
        expect(today.dayName, 'Treino A');
        expect(today.exercises.map((e) => e.nome), ['Supino', 'Remada']);
      } finally {
        container.dispose();
      }
    },
  );

  test('clearing weight removes completion immediately and on native sync', () {
    final timer = RestTimerNotifier(totalSeconds: 60, totalSets: 3);
    try {
      timer.setWeight('20');
      timer.syncExecution(3, finished: true);
      expect(timer.state.finished, isTrue);
      timer.setWeight('');
      expect(timer.state.finished, isFalse);
      timer.syncExecution(3, finished: true);
      expect(timer.state.finished, isFalse);
    } finally {
      timer.dispose();
    }
  });
  test(
    'full records, original plan, swaps and start survive restart and a smaller native queue',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId;
      cache.start('Treino A', DateTime(2026, 10, 16, 8));
      cache.capture(('Supino', 60, 3), record('20'));
      await cache.swap('Remada', {
        'nome': 'Remada baixa',
        'series': '3',
        'repeticoes': '12',
        'descanso': '90s',
      });
      cache.mergeNative({
        'day': 'Treino A',
        'exercises': [
          {'name': 'Remada baixa', 'restSeconds': 90, 'sets': 3},
        ],
        'completed': [1],
        'index': 0,
        'phase': 'rest',
        'weights': {},
        'startedAt': DateTime(2026, 10, 16, 8, 10).millisecondsSinceEpoch,
      });
      await cache.flush();
      final restored = WorkoutSessionCache(store, () async => token('a'));
      await restored.open('Treino A', []);
      expect(restored.activeId, id);
      expect(restored.record(('Supino', 60, 3))!['weight'], '20');
      expect(restored.record(('Supino', 60, 3))!['observation'], 'last set');
      expect(restored.record(('Supino', 60, 3))!['finished'], isTrue);
      expect(restored.record(('Remada baixa', 90, 3))!['completedSets'], 1);
      expect(restored.startedAt, DateTime(2026, 10, 16, 8));
      expect((restored.active!['originalPlan'] as List)[1]['nome'], 'Remada');
      expect((restored.active!['plan'] as List)[1]['nome'], 'Remada baixa');
    },
  );
  test(
    'failed upload persists an immutable outbox; restart retries the same UUID once',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      final body = payload();
      await cache.stage(id, body);
      body['mood'] = 'edited';
      await expectLater(
        cache.sync((_) async => throw StateError('response lost')),
        throwsStateError,
      );
      expect(cache.pendingCount, 2);
      final retry = WorkoutSessionCache(store, () async => token('a'));
      final requests = <Map<String, dynamic>>[];
      await Future.wait([
        retry.sync((p) async {
          requests.add(p);
        }),
        retry.sync((p) async {
          requests.add(p);
        }),
      ]);
      expect(requests.length, 2);
      expect(requests.last['sessionId'], id);
      expect(requests.last['ownerId'], 'a');
      expect(requests.last['mood'], 'ok');
      expect(retry.pendingCount, 0);
      await retry.stage(id, {...payload(), 'mood': 'changed again'});
      await retry.sync((p) async {
        requests.add(p);
      });
      expect(requests.length, 2);
    },
  );
  test(
    'pending uploads and drafts are isolated when accounts change',
    () async {
      final store = MemoryStore();
      var user = 'a';
      final cache = WorkoutSessionCache(store, () async => token(user));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      await cache.stage(id, payload());
      user = 'b';
      await cache.bind();
      expect(cache.pendingCount, 0);
      expect(cache.active, isNull);
      await cache.sync(
        (_) async => fail('must not upload account a using account b'),
      );
      await cache.open('Treino A', plan);
      expect(cache.activeId, isNot(id));
      user = 'a';
      await cache.bind();
      expect(cache.pendingCount, 2);
      await cache.sync((p) async => expect(p['ownerId'], 'a'));
    },
  );
  test(
    'a storage failure must not allow an undurable upload on a second attempt',
    () async {
      final store = MemoryStore();
      final cache = WorkoutSessionCache(store, () async => token('a'));
      await cache.open('Treino A', plan);
      final id = cache.activeId!;
      store.fail = true;
      await expectLater(cache.stage(id, payload()), throwsStateError);
      await expectLater(cache.stage(id, payload()), throwsStateError);
      store.fail = false;
      await cache.stage(id, payload());
      final restored = WorkoutSessionCache(store, () async => token('a'));
      await restored.bind();
      expect(restored.pendingCount, 2);
    },
  );
}
