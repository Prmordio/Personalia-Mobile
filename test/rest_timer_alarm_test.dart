import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/notifications/rest_alarm.dart';
import 'package:personalia_app/features/workout/presentation/rest_timer_screen.dart';
import 'package:personalia_app/features/workout/state/active_workout_session.dart';

class _FakeAlarm implements RestAlarm {
  final events = <String>[];

  @override
  Future<void> schedule({required int id, required Duration after, required String exerciseName}) async =>
      events.add('schedule:${after.inSeconds}');

  @override
  Future<void> cancel(int id) async => events.add('cancel');

  @override
  Future<void> fireNow({required int id, required String exerciseName}) async => events.add('fire:$exerciseName');
}

void main() {
  late _FakeAlarm alarm;
  late int setsStarted;
  late RestTimerNotifier timer;

  setUp(() {
    alarm = _FakeAlarm();
    setsStarted = 0;
    timer = RestTimerNotifier(
      totalSeconds: 3,
      totalSets: 4,
      exerciseName: 'Remada Baixa',
      alarm: alarm,
      onSetStarted: () => setsStarted++,
    );
  });

  tearDown(() => timer.dispose());

  testWidgets('should_schedule_the_alarm_when_the_rest_starts', (tester) async {
    timer.toggle();

    expect(alarm.events, ['schedule:3']);
    expect(setsStarted, 1);
    expect(timer.state.completedSets, 1);
    timer.reset();
  });

  testWidgets('should_cancel_on_pause_and_reschedule_the_remaining_time_on_resume', (tester) async {
    timer.toggle();
    await tester.pump(const Duration(seconds: 1));
    timer.toggle(); // pausa
    timer.toggle(); // retoma

    expect(alarm.events, ['schedule:3', 'cancel', 'schedule:2']);
    expect(setsStarted, 1, reason: 'retomar não é uma série nova');
    timer.reset();
  });

  testWidgets('should_reschedule_when_adding_15_seconds', (tester) async {
    timer.toggle();
    timer.addSeconds(15);

    expect(alarm.events.last, 'schedule:18');
    timer.reset();
  });

  testWidgets('should_alert_immediately_when_the_rest_ends_with_the_app_open', (tester) async {
    timer.toggle();
    await tester.pump(const Duration(seconds: 3));

    expect(timer.state.remaining, 0);
    expect(alarm.events.sublist(alarm.events.length - 2), ['cancel', 'fire:Remada Baixa']);
  });

  testWidgets('should_cancel_the_alarm_on_reset', (tester) async {
    timer.toggle();
    timer.reset();

    expect(alarm.events.last, 'cancel');
    expect(timer.state.running, isFalse);
  });

  test('should_consider_the_workout_in_progress_only_for_the_same_day_and_plan_day', () {
    final session = ActiveWorkoutSession(dayName: 'Treino A', startedAt: DateTime(2026, 9, 29, 8));

    expect(session.isFor('Treino A', DateTime(2026, 9, 29, 20)), isTrue);
    expect(session.isFor('Treino B', DateTime(2026, 9, 29, 20)), isFalse);
    expect(session.isFor('Treino A', DateTime(2026, 9, 30, 8)), isFalse);
  });
}
