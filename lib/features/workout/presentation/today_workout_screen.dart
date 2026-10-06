import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/app_api.dart';
import '../../home/state/today_workout_override.dart';
import '../data/exercise_image_provider.dart';
import '../data/workout_summary.dart';
import '../state/active_workout_session.dart';
import 'rest_timer_screen.dart';
import 'widgets/exercise_video_sheet.dart';
import 'workout_finish_screen.dart';

class TodayWorkoutScreen extends ConsumerStatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  bool _showFinished = false;
  bool _finishTriggered = false;

  void _openFinishScreen(List<WorkoutExercise> exercises, String dayName) {
    final session = ref.read(activeWorkoutSessionProvider);
    final summary = WorkoutSummary.fromProviders(
      dayName: dayName,
      startedAt: session?.startedAt ?? DateTime.now(),
      exercises: exercises
          .map((e) => (nome: e.nome, series: e.series, repeticoes: e.repeticoes, descanso: e.descanso))
          .toList(),
      readState: (key) => ref.read(restTimerProvider(key)),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutFinishScreen(summary: summary)),
    );
  }

  Future<void> _confirmFinish(List<WorkoutExercise> exercises, String dayName, bool allDone) async {
    if (allDone) {
      _openFinishScreen(exercises, dayName);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar treino?'),
        content: const Text('Ainda há exercícios não concluídos. Deseja finalizar assim mesmo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, finalizar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _openFinishScreen(exercises, dayName);
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(effectiveTodayWorkoutProvider);
    // Constrói mapa de último peso varrendo os 10 treinos mais recentes (mais antigo sobrescrito pelo mais novo).
    final historyAsync = ref.watch(workoutHistoryProvider);
    final lastWeights = <String, String>{};
    final history = historyAsync.asData?.value ?? [];
    for (final workout in history.reversed) {
      for (final ex in workout.exercises) {
        if (ex.weight != null) lastWeights[ex.name.trim().toLowerCase()] = ex.weight!;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Treino de Hoje')),
      body: todayAsync.when(
        data: (today) {
          if (today.isRest) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Hoje é dia de descanso. 😴', textAlign: TextAlign.center),
              ),
            );
          }

          final exercises = today.exercises;

          // Compute finished state for each exercise
          final timerStates = {
            for (final ex in exercises)
              ex.nome: ref.watch(restTimerProvider((ex.nome, parseRestSeconds(ex.descanso), parseSetsCount(ex.series))))
          };

          final pending = exercises.where((e) => !timerStates[e.nome]!.finished).toList();
          final finished = exercises.where((e) => timerStates[e.nome]!.finished).toList();
          final allDone = exercises.isNotEmpty && pending.isEmpty;

          // Auto-trigger finish screen when all exercises done
          if (allDone && !_finishTriggered) {
            _finishTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openFinishScreen(exercises, today.dayName);
            });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(today.dayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (today.focusLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(today.focusLabel, style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              if (exercises.isEmpty) const Text('Nenhum exercício encontrado para hoje.'),
              // Pending exercises
              for (final ex in pending)
                _ExerciseCard(
                  exercise: ex,
                  lastWeight: lastWeights[ex.nome.trim().toLowerCase()],
                  dayName: today.dayName,
                ),
              // Toggle for finished
              if (finished.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showFinished = !_showFinished),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          _showFinished ? Icons.expand_less : Icons.expand_more,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showFinished
                              ? 'Ocultar concluídos (${finished.length})'
                              : 'Mostrar concluídos (${finished.length})',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showFinished)
                  for (final ex in finished)
                    _ExerciseCard(
                      exercise: ex,
                      lastWeight: lastWeights[ex.nome.trim().toLowerCase()],
                      dayName: today.dayName,
                    ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Não foi possível carregar o treino de hoje.')),
      ),
      floatingActionButton: todayAsync.asData?.value != null && !todayAsync.value!.isRest && todayAsync.value!.exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final today = todayAsync.value!;
                final timerStates = {
                  for (final ex in today.exercises)
                    ex.nome: ref.read(restTimerProvider((ex.nome, parseRestSeconds(ex.descanso), parseSetsCount(ex.series))))
                };
                final allDone = today.exercises.isNotEmpty && today.exercises.every((e) => timerStates[e.nome]!.finished);
                _confirmFinish(today.exercises, today.dayName, allDone);
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.emoji_events),
              label: const Text('Finalizar treino'),
            )
          : null,
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.exercise, this.lastWeight, this.dayName});

  final WorkoutExercise exercise;
  final String? lastWeight;
  final String? dayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSeconds = parseRestSeconds(exercise.descanso);
    final totalSets = parseSetsCount(exercise.series);
    final timerState = ref.watch(restTimerProvider((exercise.nome, totalSeconds, totalSets)));
    final finished = timerState.finished;
    final inProgress = !finished && timerState.completedSets > 0;
    final isCardio = exercise.modeloDeTreino?.toLowerCase() == 'cardio';
    final imageBytes = ref.watch(exerciseImageProvider(exercise.nome)).asData?.value;

    Color? cardColor;
    if (finished) {
      cardColor = const Color(0xFFE8F5E9);
    } else if (inProgress) {
      cardColor = const Color(0xFFFFF3E0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(exercise.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (finished)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: Colors.white, size: 11),
                                  SizedBox(width: 3),
                                  Text('Concluído', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          else if (inProgress)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                isCardio ? 'Em execução' : '${timerState.completedSets}/$totalSets séries',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (isCardio) ...[
                            if (exercise.repeticoes != null) _Stat('Meta', exercise.repeticoes!),
                            if (finished) _Stat('Tempo', timerState.weight),
                            _Stat('Último tempo', lastWeight ?? '—'),
                          ] else ...[
                            if (exercise.series != null) _Stat('Séries', exercise.series!),
                            if (exercise.repeticoes != null) _Stat('Repetições', exercise.repeticoes!),
                            if (exercise.descanso != null) _Stat('Descanso', exercise.descanso!),
                            _Stat('Último peso', lastWeight != null ? '$lastWeight kg' : '—'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (imageBytes != null) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: finished ? Icons.check_circle : inProgress ? Icons.replay_circle_filled : Icons.play_circle_fill,
                  label: finished ? 'Feito' : inProgress ? 'Continuar' : 'Iniciar',
                  color: finished ? Colors.green : const Color(0xFFFF6B35),
                  onPressed: () => context.push(
                    '/workout/rest-timer',
                    extra: RestTimerArgs(exercise: exercise, lastWeight: lastWeight, dayName: dayName),
                  ),
                ),
                _ActionButton(
                  icon: Icons.search,
                  label: 'Vídeos',
                  color: const Color(0xFF2196F3),
                  onPressed: () => showExerciseVideoSheet(context, exerciseName: exercise.nome),
                ),
                _ActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Trocar',
                  color: const Color(0xFF42A5F5),
                  onPressed: () => context.push('/coming-soon/trocar-exercicio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onPressed});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
