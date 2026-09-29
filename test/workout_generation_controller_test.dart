import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/home/state/workout_generation_controller.dart';

class _FakeAppApi extends AppApi {
  _FakeAppApi() : super(Dio());

  int generateCalls = 0;
  bool started = true;
  Object? generateError;
  Completer<void>? generateGate;
  int pollsUntilReady = 2;
  int polls = 0;
  String generationStatus = 'running';

  @override
  Future<bool> generateWorkout() async {
    generateCalls++;
    if (generateGate != null) await generateGate!.future;
    if (generateError != null) throw generateError!;
    return started;
  }

  @override
  Future<String> getGenerationStatus() async => generationStatus;

  @override
  Future<CurrentWorkout?> getCurrentWorkout() async {
    polls++;
    return polls >= pollsUntilReady ? CurrentWorkout(name: 'Treino', days: const []) : null;
  }
}

void main() {
  late _FakeAppApi api;
  late int readyCalls;
  late WorkoutGenerationController controller;

  setUp(() {
    api = _FakeAppApi();
    readyCalls = 0;
    controller = WorkoutGenerationController(
      api,
      onWorkoutReady: () => readyCalls++,
      pollInterval: Duration.zero,
      maxPollAttempts: 5,
    );
  });

  test('should_lock_the_button_while_waiting_for_the_request', () async {
    api.generateGate = Completer<void>();

    final first = controller.generate();
    expect(controller.state, WorkoutGenerationStatus.requesting);

    expect(await controller.generate(), GenerateOutcome.alreadyRunning);
    expect(api.generateCalls, 1);

    api.generateGate!.complete();
    expect(await first, GenerateOutcome.started);
  });

  test('should_poll_until_the_workout_is_ready_and_unlock', () async {
    expect(await controller.generate(), GenerateOutcome.started);
    expect(controller.state, WorkoutGenerationStatus.generating);

    await pumpEventQueue();

    expect(controller.state, WorkoutGenerationStatus.idle);
    expect(readyCalls, 1);
  });

  test('should_ignore_taps_while_generating', () async {
    api.pollsUntilReady = 100;
    await controller.generate();

    expect(await controller.generate(), GenerateOutcome.alreadyRunning);
    expect(api.generateCalls, 1);
  });

  test('should_unlock_and_report_when_subscription_is_required', () async {
    api.started = false;

    expect(await controller.generate(), GenerateOutcome.subscriptionRequired);
    expect(controller.state, WorkoutGenerationStatus.idle);
    expect(api.polls, 0);
  });

  test('should_unlock_when_the_request_fails', () async {
    api.generateError = Exception('network');

    expect(await controller.generate(), GenerateOutcome.failed);
    expect(controller.state, WorkoutGenerationStatus.idle);
  });

  test('should_time_out_and_allow_checking_again_without_generating_again', () async {
    api.pollsUntilReady = 7;
    await controller.generate();
    await pumpEventQueue();
    expect(controller.state, WorkoutGenerationStatus.timedOut);

    await controller.checkAgain();

    expect(controller.state, WorkoutGenerationStatus.idle);
    expect(readyCalls, 1);
    expect(api.generateCalls, 1);
  });

  test('should_stop_waiting_and_unlock_when_the_backend_reports_failure', () async {
    api.pollsUntilReady = 100;
    api.generationStatus = 'failed';

    await controller.generate();
    await pumpEventQueue();

    expect(controller.state, WorkoutGenerationStatus.failed);
    expect(controller.isBusy, isFalse);
    expect(readyCalls, 0);
  });

  test('should_allow_generating_again_after_a_failure', () async {
    api.pollsUntilReady = 100;
    api.generationStatus = 'failed';
    await controller.generate();
    await pumpEventQueue();

    expect(await controller.generate(), GenerateOutcome.started);
    expect(api.generateCalls, 2);
  });

  test('should_not_report_failure_when_the_workout_appears_as_the_status_is_cleared', () async {
    api.pollsUntilReady = 2;
    api.generationStatus = 'idle';

    await controller.generate();
    await pumpEventQueue();

    expect(controller.state, WorkoutGenerationStatus.idle);
    expect(readyCalls, 1);
  });
}
