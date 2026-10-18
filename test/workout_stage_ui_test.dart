import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:personalia_app/features/workout/data/workout_summary.dart';
import 'package:personalia_app/features/workout/presentation/workout_finish_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/home/state/today_workout_override.dart';
import 'package:personalia_app/features/workout/data/exercise_image_provider.dart';
import 'package:personalia_app/features/workout/presentation/today_workout_screen.dart';
import 'package:personalia_app/features/workout/presentation/rest_timer_screen.dart';
import 'package:personalia_app/features/workout/state/active_workout_session.dart';
import 'package:personalia_app/features/workout/state/workout_session_cache.dart';
import 'package:personalia_app/features/workout/state/workout_live_activity.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

class _Store implements WorkoutCacheStore {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}

class _DelayedStore extends _Store {
  final ready = Completer<String?>();
  bool failWrites = false;
  @override
  Future<String?> read(String key) => ready.future;
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('storage full');
    await super.write(key, value);
  }
}

class _RecordingApi extends AppApi {
  _RecordingApi() : super(Dio());
  final requests = <Map<String, dynamic>>[];
  @override
  Future<void> syncCachedWorkout(Map<String, dynamic> payload) async {
    requests.add(payload);
  }
}

void main() {
  testWidgets(
    'optional workout feedback is saved with a compact finish operation',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        WorkoutLiveController.channel,
        (_) async => null,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          WorkoutLiveController.channel,
          null,
        ),
      );
      final cache = WorkoutSessionCache(
        _Store(),
        () async => 'x.${base64Url.encode(utf8.encode('{"sub":"test"}'))}.x',
      );
      await cache.open('A', [
        {
          'nome': 'Supino',
          'series': '3',
          'repeticoes': '10',
          'descanso': '60s',
        },
      ]);
      cache.capture(
        ('Supino', 60, 3),
        {
          'remaining': 0,
          'completedSets': 3,
          'weight': '20',
          'observation': 'ok',
          'running': false,
          'finished': true,
          'elapsed': 0,
        },
      );
      final api = _RecordingApi();
      final container = ProviderContainer(
        overrides: [
          workoutSessionCacheProvider.overrideWithValue(cache),
          appApiProvider.overrideWithValue(api),
        ],
      );
      final summary = WorkoutSummary(
        sessionId: cache.activeId,
        dayName: 'A',
        startedAt: cache.startedAt!,
        finishedAt: DateTime.now(),
        exercises: [
          const ExerciseSummary(
            nome: 'Supino',
            weight: '20',
            completedSets: 3,
            totalSets: 3,
            finished: true,
          ),
        ],
      );
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WorkoutFinishScreen(summary: summary),
                      ),
                    ),
                    child: const Text('Open summary'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open summary'));
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(const Locale('en'));
        final field = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText == l.workoutFeedbackLabel,
        );
        await tester.scrollUntilVisible(
          field,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field, '  Good session  ');
        await tester.ensureVisible(find.text(l.btnFinishWithoutCard));
        await tester.tap(find.text(l.btnFinishWithoutCard));
        await tester.pumpAndSettle();
        expect(api.requests.last['_action'], 'finish');
        expect(api.requests.last['feedback'], 'Good session');
        expect(api.requests.last.containsKey('exercises'), isFalse);
        expect(cache.lastCompletion!['exercises'], isNotEmpty);
        expect(find.text('Open summary'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      }
    },
  );

  for (final failStorage in [false, true]) {
    testWidgets(
      'finish action waits for a durable cache (failure=$failStorage)',
      (tester) async {
        final store = _DelayedStore()..failWrites = failStorage;
        final cache = WorkoutSessionCache(
          store,
          () async => 'x.${base64Url.encode(utf8.encode('{"sub":"test"}'))}.x',
        );
        final today = TodayWorkout(
          isRest: false,
          dayName: 'A',
          focusLabel: '',
          exercises: [
            WorkoutExercise(
              nome: 'Supino',
              series: '3',
              repeticoes: '10',
              descanso: '60s',
            ),
          ],
        );
        final container = ProviderContainer(
          overrides: [
            workoutSessionCacheProvider.overrideWithValue(cache),
            effectiveTodayWorkoutProvider.overrideWith((ref) async => today),
            workoutHistoryProvider.overrideWith((ref) async => []),
            exerciseImageProvider('Supino').overrideWith((ref) async => null),
          ],
        );
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const TodayWorkoutScreen(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.byType(FloatingActionButton), findsNothing);
          expect(cache.activeId, isNull);
          store.ready.complete(null);
          await tester.pumpAndSettle();
          expect(
            find.byType(FloatingActionButton),
            failStorage ? findsNothing : findsOneWidget,
          );
          if (failStorage) {
            expect(find.byType(TextButton), findsOneWidget);
            store.failWrites = false;
            await tester.tap(find.byType(TextButton));
            await tester.pumpAndSettle();
            expect(find.byType(FloatingActionButton), findsOneWidget);
          }
          expect(cache.activeId, isNotNull);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
        }
      },
    );
  }

  testWidgets(
    'opening a workout starts the session; only completed exercises offer cancellation',
    (tester) async {
      final cache = WorkoutSessionCache(
        _Store(),
        () async => 'x.${base64Url.encode(utf8.encode('{"sub":"test"}'))}.x',
      );
      final today = TodayWorkout(
        isRest: false,
        dayName: 'A',
        focusLabel: '',
        exercises: [
          WorkoutExercise(
            nome: 'Supino',
            series: '3',
            repeticoes: '10',
            descanso: '60s',
          ),
          WorkoutExercise(
            nome: 'Remada',
            series: '3',
            repeticoes: '10',
            descanso: '60s',
          ),
        ],
      );
      await cache.open('A', [
        for (final e in today.exercises)
          {
            'nome': e.nome,
            'series': e.series,
            'repeticoes': e.repeticoes,
            'descanso': e.descanso,
          },
      ]);
      cache.capture(
        ('Supino', 60, 3),
        {
          'remaining': 0,
          'completedSets': 3,
          'weight': '20',
          'observation': 'ok',
          'running': false,
          'finished': true,
          'elapsed': 0,
        },
      );
      final container = ProviderContainer(
        overrides: [
          workoutSessionCacheProvider.overrideWithValue(cache),
          effectiveTodayWorkoutProvider.overrideWith((ref) async => today),
          workoutHistoryProvider.overrideWith((ref) async => []),
          exerciseImageProvider('Supino').overrideWith((ref) async => null),
          exerciseImageProvider('Remada').overrideWith((ref) async => null),
        ],
      );
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const TodayWorkoutScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(const Locale('en'));
        expect(container.read(activeWorkoutSessionProvider)?.dayName, 'A');
        expect(
          container.read(restTimerProvider(('Remada', 60, 3))).completedSets,
          0,
        );
        expect(find.text(l.cancelCompletedExerciseLabel), findsNothing);
        await tester.tap(find.text(l.showCompleted(1)));
        await tester.pumpAndSettle();
        expect(find.text(l.editExerciseLabel), findsOneWidget);
        expect(find.text(l.cancelCompletedExerciseLabel), findsOneWidget);
        await tester.ensureVisible(find.text(l.cancelCompletedExerciseLabel));
        await tester.tap(find.text(l.cancelCompletedExerciseLabel));
        await tester.pumpAndSettle();
        expect(find.text(l.cancelCompletedExerciseMessage), findsOneWidget);
        await tester.tap(find.text(l.cancelar));
        await tester.pumpAndSettle();
        expect(cache.record(('Supino', 60, 3))!['finished'], isTrue);
        await tester.tap(find.text(l.cancelCompletedExerciseLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.sim));
        await tester.pumpAndSettle();
        expect(cache.record(('Supino', 60, 3))!['finished'], isFalse);
        expect(cache.record(('Supino', 60, 3))!['weight'], '');
        expect(
          container.read(restTimerProvider(('Supino', 60, 3))).completedSets,
          0,
        );
        final actions = <String>[];
        await cache.sync((p) async => actions.add(p['_action'] as String));
        expect(actions, ['start', 'exercise', 'removeExercise']);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      }
    },
  );
}
