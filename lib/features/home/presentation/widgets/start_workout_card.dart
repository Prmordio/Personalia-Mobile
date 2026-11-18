import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workout/presentation/workout_session_actions.dart';
import '../../../workout/state/active_workout_session.dart';
import '../../../workout/state/completed_workout_session.dart';
import '../../../workout/state/rest_timer_controller.dart';
import '../../../workout/state/workout_session_cache.dart';
import '../../data/app_api.dart';
import '../../state/today_workout_override.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StartWorkoutCard extends ConsumerWidget {
  const StartWorkoutCard({super.key, 
    required this.todayAsync,
    required this.plan,
    this.isActive = true,
  });
  final AsyncValue<TodayWorkout> todayAsync;
  final CurrentWorkout plan;
  final bool isActive;

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  /// "Trocar treino": escolher outro dia do plano para treinar hoje (igual ao bot).
  Future<void> _chooseDay(BuildContext context, WidgetRef ref) async {
    final current = todayAsync.asData?.value.dayName;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                context.l10n.chooseWorkoutDayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            for (final day in plan.days)
              ListTile(
                title: Text(day.dayName),
                subtitle: Text(
                  context.l10n.exercisesCount(day.exercises.length),
                ),
                trailing: day.dayName == current
                    ? const Icon(Icons.check, color: AppColors.orange)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(day.dayName),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == current) return;
    ref.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(
      dayName: chosen,
      date: DateTime.now(),
    );
    if (context.mounted) context.push('/workout/today');
  }

  void _resetAndTrainAgain(
    BuildContext context,
    WidgetRef ref,
    TodayWorkout today,
  ) {
    for (final ex in today.exercises) {
      final key = (
        ex.nome,
        parseRestSeconds(ex.descanso),
        parseSetsCount(ex.series),
      );
      ref.read(restTimerProvider(key).notifier).resetForNewSession();
    }

    // Prioriza a sessão concluída em memória (mais recente que o cache do lastWorkoutProvider).
    // Fallback: último treino do banco. Fallback final: o dia atual.
    final completedSession = ref.read(completedWorkoutSessionProvider);
    final lastWorkout = ref.read(lastWorkoutProvider).asData?.value;
    final lastDayName =
        completedSession?.dayName ?? lastWorkout?.dayName ?? today.dayName;

    // Filtra dias de descanso para não entrar na rotação A → Descanso → B.
    final nonRestDays = plan.days
        .where((d) => !d.dayName.toLowerCase().contains('descanso'))
        .toList();
    final days = nonRestDays.isNotEmpty ? nonRestDays : plan.days;
    final currentIndex = days.indexWhere((d) => d.dayName == lastDayName);
    final nextIndex = currentIndex >= 0 ? (currentIndex + 1) % days.length : 0;
    final nextDay = days[nextIndex];

    ref.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(
      dayName: nextDay.dayName,
      date: DateTime.now(),
    );
    ref.read(completedWorkoutSessionProvider.notifier).state = null;
    ref.invalidate(lastWorkoutProvider);
    context.push('/workout/today');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = todayAsync.asData?.value;
    final session = ref.watch(activeWorkoutSessionProvider);
    final completed = ref.watch(completedWorkoutSessionProvider);
    final lastWorkout = ref.watch(lastWorkoutProvider).asData?.value;

    final cached = ref.read(workoutSessionCacheProvider).active;
    final inProgress =
        cached != null ||
        (session != null && today != null && session.dayName == today.dayName);
    final completedInSession =
        completed != null &&
        completed.isToday() &&
        today != null &&
        completed.dayName == today.dayName;
    final completedFromDB = lastWorkout != null && lastWorkout.isToday;
    final isDoneToday = !inProgress && (completedInSession || completedFromDB);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDoneToday
                        ? context.l10n.workoutDoneToday
                        : inProgress
                        ? context.l10n.workoutInProgress
                        : context.l10n.workoutStart,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (inProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.workoutStatusInProgress,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isDoneToday) ...[
              Text(
                completedInSession
                    ? completed.dayName
                    : (lastWorkout?.dayName ?? ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (completedInSession) ...[
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completed.durationFormatted,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                  ] else if (lastWorkout?.duration != null) ...[
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(lastWorkout!.duration!),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    completedInSession
                        ? context.l10n.workoutExerciseCount(
                            completed.completedCount,
                            completed.totalCount,
                          )
                        : context.l10n.exercisesCount(
                            lastWorkout?.exercises.length ?? 0,
                          ),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ] else
              todayAsync.when(
                data: (today) {
                  if (today.isRest) return Text(context.l10n.workoutRestDay);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        today.dayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (today.focusLabel.isNotEmpty)
                        Text(
                          today.focusLabel,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, s) => Text(context.l10n.errLoadTodayWorkout),
              ),
            const SizedBox(height: 16),
            if (isDoneToday)
              OutlinedButton.icon(
                onPressed: !isActive || today == null
                    ? null
                    : () => _resetAndTrainAgain(context, ref, today),
                icon: const Icon(Icons.replay),
                label: Text(context.l10n.btnTrainAgain),
              )
            else
              ElevatedButton(
                onPressed: !isActive || todayAsync.asData?.value.isRest == true
                    ? null
                    : () => context.push('/workout/today'),
                child: Text(
                  inProgress
                      ? context.l10n.btnContinueWorkout
                      : context.l10n.workoutStart,
                ),
              ),
            if (inProgress)
              TextButton.icon(
                onPressed: () => cancelWorkoutSession(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l10n.cancelWorkoutLabel),
              ),
            if (plan.days.length > 1 && !inProgress) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: isActive ? () => _chooseDay(context, ref) : null,
                icon: const Icon(Icons.swap_horiz),
                label: Text(context.l10n.btnSwitchWorkout),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
