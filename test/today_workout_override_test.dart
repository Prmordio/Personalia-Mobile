import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/home/state/today_workout_override.dart';

WorkoutExercise _exercise(String nome) => WorkoutExercise.fromJson({'nome': nome});

void main() {
  final suggested = TodayWorkout(isRest: false, dayName: 'Treino A', focusLabel: 'Peito', exercises: [_exercise('Supino')]);
  final plan = CurrentWorkout(
    name: 'PPL',
    days: [
      WorkoutDay(dayName: 'Treino A', exercises: [_exercise('Supino')]),
      WorkoutDay(dayName: 'Treino B', exercises: [_exercise('Agachamento'), _exercise('Leg press')]),
    ],
  );

  ProviderContainer container({TodayWorkout? today}) {
    final c = ProviderContainer(
      overrides: [
        todayWorkoutProvider.overrideWith((ref) async => today ?? suggested),
        currentWorkoutProvider.overrideWith((ref) async => plan),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('should_use_the_backend_suggestion_without_a_swap', () async {
    final c = container();

    final today = await c.read(effectiveTodayWorkoutProvider.future);

    expect(today.dayName, 'Treino A');
  });

  test('should_use_the_chosen_plan_day_after_swapping', () async {
    final c = container();
    c.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(dayName: 'Treino B', date: DateTime.now());

    final today = await c.read(effectiveTodayWorkoutProvider.future);

    expect(today.dayName, 'Treino B');
    expect(today.exercises.map((e) => e.nome), ['Agachamento', 'Leg press']);
  });

  test('should_let_the_user_train_on_a_rest_day_by_swapping', () async {
    final c = container(today: TodayWorkout(isRest: true, dayName: '', focusLabel: '', exercises: const []));
    c.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(dayName: 'Treino B', date: DateTime.now());

    final today = await c.read(effectiveTodayWorkoutProvider.future);

    expect(today.isRest, isFalse);
    expect(today.dayName, 'Treino B');
  });

  test('should_ignore_a_swap_made_on_another_day', () async {
    final c = container();
    c.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(
      dayName: 'Treino B',
      date: DateTime.now().subtract(const Duration(days: 1)),
    );

    final today = await c.read(effectiveTodayWorkoutProvider.future);

    expect(today.dayName, 'Treino A');
  });

  test('should_fall_back_when_the_chosen_day_no_longer_exists', () async {
    final c = container();
    c.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(dayName: 'Treino Z', date: DateTime.now());

    final today = await c.read(effectiveTodayWorkoutProvider.future);

    expect(today.dayName, 'Treino A');
  });
}
