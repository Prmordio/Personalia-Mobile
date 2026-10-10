import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/app_api.dart';
import '../../home/state/today_workout_override.dart';
import '../data/exercise_image_provider.dart';
import '../data/workout_summary.dart';
import '../state/active_workout_session.dart';
import 'rest_timer_screen.dart';
import 'swap_exercise_screen.dart';
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

  final Map<String, WorkoutExercise> _sessionSwaps = {};

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

  Future<void> _handleSwapExercise(WorkoutExercise exercise) async {
    final alt = await context.push<ExerciseAlternative>(
      '/workout/swap-exercise',
      extra: SwapExerciseArgs(exercise: exercise),
    );
    if (alt != null && mounted) {
      setState(() {
        _sessionSwaps[exercise.nome.trim().toLowerCase()] = WorkoutExercise(
          nome: alt.nome,
          series: alt.series ?? exercise.series,
          repeticoes: alt.repeticoes ?? exercise.repeticoes,
          modeloDeTreino: exercise.modeloDeTreino,
          descanso: exercise.descanso,
        );
      });
    }
  }

  Future<void> _handleStartExercise(
    WorkoutExercise original,
    WorkoutExercise effective,
    String? lastWeight,
    String? lastObservation,
    String? dayName,
    List<WorkoutExercise> allExercises,
  ) async {
    // Verifica se outro exercício está em andamento (iniciado mas não finalizado).
    for (final ex in allExercises) {
      final eff = _effectiveFor(ex);
      if (eff.nome.trim().toLowerCase() == effective.nome.trim().toLowerCase()) continue;
      final s = parseRestSeconds(eff.descanso);
      final t = parseSetsCount(eff.series);
      final ts = ref.read(restTimerProvider((eff.nome, s, t)));
      if (ts.completedSets > 0 && !ts.finished) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exercício em andamento'),
            content: Text(
              '"${eff.nome}" ainda está em andamento.\n\nDeseja abandoná-lo e iniciar "${effective.nome}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sim, trocar'),
              ),
            ],
          ),
        );
        if (confirm != true || !mounted) return;
        break;
      }
    }

    await context.push(
      '/workout/rest-timer',
      extra: RestTimerArgs(exercise: effective, lastWeight: lastWeight, lastObservation: lastObservation, dayName: dayName),
    );
    if (!mounted) return;

    final totalSeconds = parseRestSeconds(effective.descanso);
    final totalSets = parseSetsCount(effective.series);
    final timerState = ref.read(restTimerProvider((effective.nome, totalSeconds, totalSets)));
    final wasSwapped = _sessionSwaps.containsKey(original.nome.trim().toLowerCase());

    if (timerState.finished && wasSwapped) {
      await _askPermanentSwap(original, effective);
    }
  }

  Future<void> _askPermanentSwap(WorkoutExercise original, WorkoutExercise effective) async {
    if (!mounted) return;
    final isPermanent = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tornar troca permanente?'),
        content: Text(
          'Deseja substituir "${original.nome}" por "${effective.nome}" no seu plano de treino?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Só desta vez'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, alterar plano'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (isPermanent != true) return;

    try {
      await ref.read(appApiProvider).swapExercisePermanently(
            originalExerciseName: original.nome,
            newName: effective.nome,
            newSeries: effective.series,
            newReps: effective.repeticoes,
          );
      setState(() => _sessionSwaps.remove(original.nome.trim().toLowerCase()));
      ref.invalidate(todayWorkoutProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar o plano. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(effectiveTodayWorkoutProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);
    final lastWeights = <String, String>{};
    final lastObservations = <String, String>{};
    final history = historyAsync.asData?.value ?? [];
    for (final workout in history.reversed) {
      for (final ex in workout.exercises) {
        if (ex.weight != null) lastWeights[ex.name.trim().toLowerCase()] = ex.weight!;
        if (ex.observation != null && ex.observation!.isNotEmpty) {
          lastObservations[ex.name.trim().toLowerCase()] = ex.observation!;
        }
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

          final timerStates = {
            for (final ex in exercises)
              ex.nome: ref.watch(restTimerProvider((_effectiveFor(ex).nome, parseRestSeconds(_effectiveFor(ex).descanso), parseSetsCount(_effectiveFor(ex).series))))
          };

          final pending = exercises.where((e) => !timerStates[e.nome]!.finished).toList();
          final finished = exercises.where((e) => timerStates[e.nome]!.finished).toList();
          final allDone = exercises.isNotEmpty && pending.isEmpty;

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
              for (final ex in pending)
                _ExerciseCard(
                  exercise: ex,
                  effectiveExercise: _effectiveFor(ex),
                  isSwapped: _sessionSwaps.containsKey(ex.nome.trim().toLowerCase()),
                  lastWeight: lastWeights[_effectiveFor(ex).nome.trim().toLowerCase()],
                  lastObservation: lastObservations[_effectiveFor(ex).nome.trim().toLowerCase()],
                  dayName: today.dayName,
                  onSwap: () => _handleSwapExercise(ex),
                  onStart: (eff, lastW, lastObs, day) => _handleStartExercise(ex, eff, lastW, lastObs, day, exercises),
                ),
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
                      effectiveExercise: _effectiveFor(ex),
                      isSwapped: _sessionSwaps.containsKey(ex.nome.trim().toLowerCase()),
                      lastWeight: lastWeights[_effectiveFor(ex).nome.trim().toLowerCase()],
                      lastObservation: lastObservations[_effectiveFor(ex).nome.trim().toLowerCase()],
                      dayName: today.dayName,
                      onSwap: () => _handleSwapExercise(ex),
                      onStart: (eff, lastW, lastObs, day) => _handleStartExercise(ex, eff, lastW, lastObs, day, exercises),
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
                    ex.nome: ref.read(restTimerProvider((_effectiveFor(ex).nome, parseRestSeconds(_effectiveFor(ex).descanso), parseSetsCount(_effectiveFor(ex).series))))
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

  WorkoutExercise _effectiveFor(WorkoutExercise original) =>
      _sessionSwaps[original.nome.trim().toLowerCase()] ?? original;
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.effectiveExercise,
    required this.isSwapped,
    this.lastWeight,
    this.lastObservation,
    this.dayName,
    required this.onSwap,
    required this.onStart,
  });

  final WorkoutExercise exercise;
  final WorkoutExercise effectiveExercise;
  final bool isSwapped;
  final String? lastWeight;
  final String? lastObservation;
  final String? dayName;
  final VoidCallback onSwap;
  final void Function(WorkoutExercise effective, String? lastWeight, String? lastObservation, String? dayName) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSeconds = parseRestSeconds(effectiveExercise.descanso);
    final totalSets = parseSetsCount(effectiveExercise.series);
    final timerState = ref.watch(restTimerProvider((effectiveExercise.nome, totalSeconds, totalSets)));
    final finished = timerState.finished;
    final inProgress = !finished && timerState.completedSets > 0;
    final isCardio = effectiveExercise.modeloDeTreino?.toLowerCase() == 'cardio';
    final imageBytes = ref.watch(exerciseImageProvider(effectiveExercise.nome)).asData?.value;

    Color? cardColor;
    if (finished) {
      cardColor = const Color(0xFFE8F5E9);
    } else if (inProgress) {
      cardColor = const Color(0xFFFFF3E0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: finished ? null : () => onStart(effectiveExercise, lastWeight, lastObservation, dayName),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(effectiveExercise.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (isSwapped)
                                    Text(
                                      'Trocado: ${exercise.nome}',
                                      style: const TextStyle(color: Colors.blue, fontSize: 11),
                                    ),
                                ],
                              ),
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
                              if (effectiveExercise.repeticoes != null) _Stat('Meta', effectiveExercise.repeticoes!),
                              if (finished) _Stat('Tempo', timerState.weight),
                              _Stat('Último tempo', lastWeight ?? '—'),
                            ] else ...[
                              if (effectiveExercise.series != null) _Stat('Séries', effectiveExercise.series!),
                              if (effectiveExercise.repeticoes != null) _Stat('Repetições', effectiveExercise.repeticoes!),
                              if (effectiveExercise.descanso != null) _Stat('Descanso', effectiveExercise.descanso!),
                              _Stat('Último peso', lastWeight != null ? '$lastWeight kg' : '—'),
                              if (lastObservation != null && lastObservation!.isNotEmpty)
                                _Stat('Última obs.', lastObservation!),
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
              // Only Vídeos (blue) and Trocar (orange) — card tap handles starting
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionButton(
                    icon: Icons.search,
                    label: 'Vídeos',
                    color: const Color(0xFF2196F3),
                    onPressed: () => showExerciseVideoSheet(context, exerciseName: effectiveExercise.nome),
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Trocar',
                    color: const Color(0xFFFF6B35),
                    onPressed: finished ? null : onSwap,
                  ),
                ],
              ),
            ],
          ),
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
  final VoidCallback? onPressed;

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
            Icon(icon, color: onPressed != null ? color : Colors.grey, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: onPressed != null ? color : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
