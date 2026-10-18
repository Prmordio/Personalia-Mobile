import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/workout/data/exercise_image_provider.dart';
import 'package:personalia_app/features/workout/presentation/rest_timer_screen.dart';
import 'package:personalia_app/features/workout/state/workout_live_activity.dart';
import 'package:personalia_app/features/workout/state/workout_live_labels.dart';
import 'package:personalia_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'changing native labels preserves the running rest and progress',
    () async {
      var native = WorkoutLiveState({
        'id': 'active',
        'flowVersion': 2,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'day': 'Treino A',
        'index': 0,
        'completed': [1],
        'phase': 'rest',
        'running': true,
        'seconds': 90,
        'anchor': DateTime.now().millisecondsSinceEpoch,
        'revision': 5,
        'exercises': [
          {'name': 'Supino', 'sets': 3, 'reps': '10', 'restSeconds': 90},
        ],
      });
      final originalAnchor = native.data['anchor'];
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(WorkoutLiveController.channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'localize') {
          final args = call.arguments as Map;
          native = WorkoutLiveState({
            ...native.data,
            'labels': jsonDecode(args['json'] as String),
          });
        }
        return jsonEncode(native.data);
      });
      final controller = WorkoutLiveController();
      try {
        await controller.refresh();
        final en = workoutLiveLabels(
          lookupAppLocalizations(const Locale('en')),
        );
        final es = workoutLiveLabels(
          lookupAppLocalizations(const Locale('es')),
        );
        await controller.localize(en);
        expect(native.data['labels']['startRest'], 'Start rest');
        await controller.localize(es);
        expect(native.data['labels']['startRest'], es['startRest']);
        expect(native.phase, 'rest');
        expect(native.running, isTrue);
        expect(native.completed, 1);
        expect(native.data['anchor'], originalAnchor);
        expect(native.data['revision'], 5);
        expect(
          calls.where((c) => c.method == 'prepare' || c.method == 'action'),
          isEmpty,
        );
      } finally {
        controller.dispose();
        messenger.setMockMethodCallHandler(WorkoutLiveController.channel, null);
      }
    },
  );
  test(
    'cancelling a completed exercise preserves another running native rest',
    () async {
      var native = WorkoutLiveState({
        'id': 'session',
        'flowVersion': 2,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'day': 'Treino A',
        'index': 1,
        'completed': [3, 1],
        'phase': 'rest',
        'running': true,
        'seconds': 90,
        'anchor': DateTime.now().millisecondsSinceEpoch,
        'revision': 5,
        'weights': {'Supino': '20', 'Remada': '30'},
        'exercises': [
          {'name': 'Supino', 'sets': 3, 'reps': '10', 'restSeconds': 90},
          {'name': 'Remada', 'sets': 3, 'reps': '10', 'restSeconds': 90},
        ],
      });
      final anchor = native.data['anchor'];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(WorkoutLiveController.channel, (
        call,
      ) async {
        if (call.method == 'prepare') {
          native = WorkoutLiveState(
            jsonDecode((call.arguments as Map)['json'] as String),
          );
        }
        return jsonEncode(native.data);
      });
      final controller = WorkoutLiveController();
      try {
        await controller.refresh();
        await controller.resetCompleted('Supino');
        expect(native.data['completed'], [0, 1]);
        expect(native.data['weights'], {'Remada': '30'});
        expect(native.phase, 'rest');
        expect(native.running, isTrue);
        expect(native.data['anchor'], anchor);
        expect(native.data['revision'], 6);
        await controller.resetCompleted('Remada');
        expect(native.phase, 'ready');
        expect(native.running, isFalse);
        expect(native.data['completed'], [0, 0]);
      } finally {
        controller.dispose();
        messenger.setMockMethodCallHandler(WorkoutLiveController.channel, null);
      }
    },
  );

  for (final language in ['pt', 'en', 'es']) {
    for (final reopening in [false, true]) {
      testWidgets(
        'completed exercise keeps editable records and translated controls ($language, reopening=$reopening)',
        (tester) async {
          final l = lookupAppLocalizations(Locale(language));
          final native = <String, dynamic>{
            'id': 'finished-session',
            'flowVersion': 2,
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'day': 'Treino A',
            'index': 0,
            'completed': [3, 0],
            'phase': 'done',
            'running': false,
            'seconds': 0,
            'anchor': DateTime.now().millisecondsSinceEpoch,
            'revision': 4,
            'labels': workoutLiveLabels(l),
            'exercises': [
              {'name': 'Supino', 'sets': 3, 'reps': '10', 'restSeconds': 90},
              {'name': 'Remada', 'sets': 3, 'reps': '12', 'restSeconds': 90},
            ],
          };
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(WorkoutLiveController.channel, (
            call,
          ) async {
            if (call.method == 'weight') {
              final args = call.arguments as Map;
              final weights = Map<String, dynamic>.from(
                native['weights'] as Map? ?? {},
              );
              weights[args['name'] as String] = args['value'];
              native['weights'] = weights;
            }
            return jsonEncode(native);
          });
          final timer = RestTimerNotifier(
            totalSeconds: 90,
            totalSets: 3,
            exerciseName: 'Supino',
          );
          timer.setWeight('20');
          timer.setObservation('original');
          timer.syncExecution(3, finished: reopening);
          final container = ProviderContainer(
            overrides: [
              restTimerProvider(('Supino', 90, 3)).overrideWith((ref) => timer),
              exerciseImageProvider('Supino').overrideWith((ref) async => null),
            ],
          );
          try {
            await container.read(workoutLiveProvider.notifier).refresh();
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: RestTimerScreen(
                    args: RestTimerArgs(
                      dayName: 'Treino A',
                      exercise: WorkoutExercise(
                        nome: 'Supino',
                        series: '3',
                        repeticoes: '10',
                        descanso: '90s',
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            timer.syncExecution(3, finished: true);
            await tester.pump();
            expect(
              find.text(l.restBtnNextExercise),
              reopening ? findsNothing : findsOneWidget,
            );
            expect(
              find.text(l.restNextNamed('Remada')),
              reopening ? findsNothing : findsOneWidget,
            );
            final weight = find.byWidgetPredicate(
              (w) =>
                  w is TextField &&
                  w.decoration?.labelText == l.restWeightLabel,
            );
            final observation = find.byWidgetPredicate(
              (w) =>
                  w is TextField &&
                  w.decoration?.labelText == l.restObservationLabel,
            );
            await tester.scrollUntilVisible(
              weight,
              250,
              scrollable: find.byType(Scrollable).first,
            );
            if (!reopening) {
              final next = find
                  .ancestor(
                    of: find.text(l.restBtnNextExercise),
                    matching: find.byType(InkWell),
                  )
                  .first;
              expect(tester.widget<InkWell>(next).onTap, isNull);
            }
            await tester.enterText(weight, '24');
            await tester.pump();
            if (!reopening) {
              final next = find
                  .ancestor(
                    of: find.text(l.restBtnNextExercise),
                    matching: find.byType(InkWell),
                  )
                  .first;
              expect(tester.widget<InkWell>(next).onTap, isNotNull);
              await tester.enterText(weight, '');
              await tester.pump();
              expect(tester.widget<InkWell>(next).onTap, isNull);
              expect(timer.state.finished, isFalse);
              await tester.enterText(weight, '24');
              await tester.pump();
            }

            await tester.scrollUntilVisible(
              observation,
              250,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.enterText(observation, 'updated');
            expect(timer.state.weight, '24');
            expect(timer.state.observation, 'updated');
            // This screen is isolated from the app root's native-state listener.
            timer.syncExecution(
              3,
              finished: container
                  .read(workoutLiveProvider)!
                  .exerciseFinished(0),
            );
            expect(timer.state.finished, isTrue);
            await tester.scrollUntilVisible(
              find.text(l.restBtnFinishExercise),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text(l.restBtnFinishExercise), findsOneWidget);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            container.dispose();
            messenger.setMockMethodCallHandler(
              WorkoutLiveController.channel,
              null,
            );
          }
        },
      );
    }
  }
}
