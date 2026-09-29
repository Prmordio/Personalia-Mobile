import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_api.dart';

/// "Trocar treino" (igual ao comando do bot): o usuário escolhe outro dia do plano para
/// treinar hoje. Vale só para a data em que foi escolhido — amanhã volta a sugestão do backend.
class TodayDayOverride {
  const TodayDayOverride({required this.dayName, required this.date});
  final String dayName;
  final DateTime date;

  bool isFor(DateTime now) => date.year == now.year && date.month == now.month && date.day == now.day;
}

final todayDayOverrideProvider = StateProvider<TodayDayOverride?>((ref) => null);

/// Treino de hoje considerando a troca: se o usuário escolheu outro dia do plano, usa esse
/// dia; senão, o sugerido pelo backend (GET /app/workout/today).
final effectiveTodayWorkoutProvider = FutureProvider.autoDispose<TodayWorkout>((ref) async {
  final override = ref.watch(todayDayOverrideProvider);
  final suggested = await ref.watch(todayWorkoutProvider.future);
  if (override == null || !override.isFor(DateTime.now())) return suggested;

  final plan = await ref.watch(currentWorkoutProvider.future);
  final chosen = plan?.days.where((d) => d.dayName == override.dayName).firstOrNull;
  if (chosen == null) return suggested;
  return TodayWorkout(isRest: false, dayName: chosen.dayName, focusLabel: '', exercises: chosen.exercises);
});
