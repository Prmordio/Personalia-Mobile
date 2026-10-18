import 'workout_session_actions.dart';
import '../state/workout_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../home/data/app_api.dart';
import '../../home/state/today_workout_override.dart';
import '../data/exercise_image_provider.dart';
import '../data/workout_summary.dart';
import '../state/active_workout_session.dart';
import 'rest_timer_screen.dart';
import 'swap_exercise_screen.dart';
import 'widgets/exercise_video_sheet.dart';
import 'widgets/exercise_list.dart';
import '../state/workout_live_activity.dart';
import 'workout_finish_screen.dart';

class TodayWorkoutScreen extends ConsumerStatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  bool _showFinished = false;
  bool _finishTriggered = false;
  bool _cacheReady = false;
  bool _cacheOpening = false;
  bool _cacheFailed = false;
  List<WorkoutExercise>? _cachedExercises;

  Map<String, dynamic> _exerciseData(WorkoutExercise e) => {
    'nome': e.nome,
    'series': e.series,
    'repeticoes': e.repeticoes,
    'descanso': e.descanso,
    'modeloDeTreino': e.modeloDeTreino,
  };
  Future<void> _restoreCachedPlan(TodayWorkout today) async {
    try {
      final cache = ref.read(workoutSessionCacheProvider);
      await cache.open(
        today.dayName,
        today.exercises.map(_exerciseData).toList(),
      );
      if (!mounted) return;
      final native = ref.read(workoutLiveProvider);
      if (native != null && native.data['day'] == today.dayName) {
        cache.mergeNative(native.data);
      } else if (native != null) {
        await ref.read(workoutLiveProvider.notifier).end();
      }
      if (!mounted) return;
      _cachedExercises =
          ((cache.active?['originalPlan'] ?? cache.active?['plan']) as List)
              .map(
                (e) => WorkoutExercise.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
      _sessionSwaps.clear();
      final swaps = cache.active?['swaps'] as Map? ?? {};
      for (final entry in swaps.entries) {
        _sessionSwaps[entry.key as String] = WorkoutExercise.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
      ref.invalidate(restTimerProvider);
      if (cache.startedAt != null) {
        ref
            .read(activeWorkoutSessionProvider.notifier)
            .state = ActiveWorkoutSession(
          dayName: today.dayName,
          startedAt: cache.startedAt!,
        );
      } else {
        ref.read(activeWorkoutSessionProvider.notifier).state = null;
      }
      setState(() {
        _cacheReady = true;
        _cacheFailed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheFailed = true;
        });
      }
    } finally {
      _cacheOpening = false;
    }
  }

  final Map<String, WorkoutExercise> _sessionSwaps = {};

  void _openFinishScreen(List<WorkoutExercise> exercises, String dayName) {
    if (!_cacheReady ||
        ref.read(workoutSessionCacheProvider).activeId == null) {
      return;
    }
    final session = ref.read(activeWorkoutSessionProvider);
    final summary = WorkoutSummary.fromProviders(
      dayName: dayName,
      sessionId: ref.read(workoutSessionCacheProvider).activeId,
      startedAt:
          session?.startedAt ??
          ref.read(workoutSessionCacheProvider).startedAt ??
          DateTime.now(),
      exercises: exercises
          .map(_effectiveFor)
          .map(
            (e) => (
              nome: e.nome,
              series: e.series,
              repeticoes: e.repeticoes,
              descanso: e.descanso,
            ),
          )
          .toList(),
      readState: (key) => ref.read(restTimerProvider(key)),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutFinishScreen(summary: summary)),
    );
  }

  Future<void> _confirmFinish(
    List<WorkoutExercise> exercises,
    String dayName,
    bool allDone,
  ) async {
    if (allDone) {
      _openFinishScreen(exercises, dayName);
      return;
    }
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.finishWorkoutTitle),
        content: Text(l.finishWorkoutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.sim),
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
      await ref
          .read(workoutSessionCacheProvider)
          .swap(exercise.nome, _exerciseData(_effectiveFor(exercise)));
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
    final editingFinished = ref
        .read(
          restTimerProvider((
            effective.nome,
            parseRestSeconds(effective.descanso),
            parseSetsCount(effective.series),
          )),
        )
        .finished;
    // Verifica se outro exercício está em andamento (iniciado mas não finalizado).
    for (final ex in allExercises) {
      if (editingFinished) break;
      final eff = _effectiveFor(ex);
      if (eff.nome.trim().toLowerCase() ==
          effective.nome.trim().toLowerCase()) {
        continue;
      }
      final s = parseRestSeconds(eff.descanso);
      final t = parseSetsCount(eff.series);
      final ts = ref.read(restTimerProvider((eff.nome, s, t)));
      if (!isCardioExercise(eff) &&
          ts.completedSets > 0 &&
          ts.weight.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.restWeightHint)));
        return;
      }
      final live = ref.read(workoutLiveProvider);
      final executing = live?.name == eff.nome && live?.phase != 'ready';
      if ((ts.completedSets > 0 || executing) && !ts.finished) {
        final l = context.l10n;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l.exerciseInProgressTitle),
            content: Text(l.exerciseInProgressMsg(eff.nome, effective.nome)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancelar),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.sim),
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
      extra: RestTimerArgs(
        exercise: effective,
        lastWeight: lastWeight,
        lastObservation: lastObservation,
        dayName: dayName,
        upcomingExercises: allExercises
            .skipWhile((e) => e.nome != original.nome)
            .skip(1)
            .map(_effectiveFor)
            .takeWhile((e) => !isCardioExercise(e))
            .where(
              (e) =>
                  ref
                      .read(
                        restTimerProvider((
                          e.nome,
                          parseRestSeconds(e.descanso),
                          parseSetsCount(e.series),
                        )),
                      )
                      .completedSets <
                  parseSetsCount(e.series),
            )
            .toList(),
      ),
    );
    if (!mounted) return;

    final totalSeconds = parseRestSeconds(effective.descanso);
    final totalSets = parseSetsCount(effective.series);
    final timerState = ref.read(
      restTimerProvider((effective.nome, totalSeconds, totalSets)),
    );
    final wasSwapped = _sessionSwaps.containsKey(
      original.nome.trim().toLowerCase(),
    );

    if (timerState.finished && wasSwapped) {
      await _askPermanentSwap(original, effective);
    }
  }

  Future<void> _askPermanentSwap(
    WorkoutExercise original,
    WorkoutExercise effective,
  ) async {
    if (!mounted) return;
    final l = context.l10n;
    final isPermanent = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.makePermanentTitle),
        content: Text(l.makePermanentMsg(original.nome, effective.nome)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.btnThisTimeOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.btnYesChangePlan),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (isPermanent != true) return;

    try {
      await ref
          .read(appApiProvider)
          .swapExercisePermanently(
            originalExerciseName: original.nome,
            newName: effective.nome,
            newSeries: effective.series,
            newReps: effective.repeticoes,
          );
      ref.invalidate(todayWorkoutProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errChangePlan)));
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
        if (ex.weight != null) {
          lastWeights[ex.name.trim().toLowerCase()] = ex.weight!;
        }
        if (ex.observation != null && ex.observation!.isNotEmpty) {
          lastObservations[ex.name.trim().toLowerCase()] = ex.observation!;
        }
      }
    }

    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.todayWorkoutTitle),
        actions: [
          if (_cacheReady)
            IconButton(
              tooltip: l.cancelWorkoutLabel,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await cancelWorkoutSession(context, ref) &&
                    context.mounted) {
                  context.pop();
                }
              },
            ),
        ],
      ),
      body: todayAsync.when(
        data: (today) {
          if (today.isRest) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.workoutRestDay, textAlign: TextAlign.center),
              ),
            );
          }

          if (!_cacheReady) {
            if (!_cacheOpening && !_cacheFailed) {
              _cacheOpening = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _restoreCachedPlan(today);
              });
            }
            return Center(
              child: _cacheFailed
                  ? TextButton(
                      onPressed: () => setState(() => _cacheFailed = false),
                      child: Text(l.genericError),
                    )
                  : const CircularProgressIndicator(),
            );
          }
          final exercises = _cachedExercises ?? today.exercises;

          final timerStates = {
            for (final ex in exercises)
              ex.nome: ref.watch(
                restTimerProvider((
                  _effectiveFor(ex).nome,
                  parseRestSeconds(_effectiveFor(ex).descanso),
                  parseSetsCount(_effectiveFor(ex).series),
                )),
              ),
          };

          // Recover full counters left by older lock-screen sessions, including
          // exercises no longer present in the native queue. An active final
          // rest must finish before its exercise is moved out of the list.
          final live = ref.watch(workoutLiveProvider);
          for (final ex in exercises) {
            final effective = _effectiveFor(ex);
            final timer = timerStates[ex.nome]!;
            final resting =
                live?.name == effective.nome && live?.phase == 'rest';
            if (!isCardioExercise(effective) &&
                !timer.finished &&
                timer.weight.trim().isNotEmpty &&
                timer.completedSets >= parseSetsCount(effective.series) &&
                !resting) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final key = (
                  effective.nome,
                  parseRestSeconds(effective.descanso),
                  parseSetsCount(effective.series),
                );
                final current = ref.read(restTimerProvider(key));
                final active = ref.read(workoutLiveProvider);
                if (!current.finished &&
                    current.weight.trim().isNotEmpty &&
                    current.completedSets >= key.$3 &&
                    !(active?.name == effective.nome &&
                        active?.phase == 'rest')) {
                  ref.read(restTimerProvider(key).notifier).finish();
                }
              });
            }
          }

          final pending = exercises
              .where((e) => !timerStates[e.nome]!.finished)
              .toList();
          final finished = exercises
              .where((e) => timerStates[e.nome]!.finished)
              .toList();
          final allDone = exercises.isNotEmpty && pending.isEmpty;
          if (!allDone) _finishTriggered = false;

          if (allDone &&
              !_finishTriggered &&
              (ModalRoute.of(context)?.isCurrent ?? false)) {
            _finishTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openFinishScreen(exercises, today.dayName);
            });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(
                today.dayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (today.focusLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  today.focusLabel,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 16),
              if (exercises.isEmpty) Text(l.todayNoExercises),
              for (final ex in pending)
                _ExerciseCard(
                  exercise: ex,
                  effectiveExercise: _effectiveFor(ex),
                  isSwapped: _sessionSwaps.containsKey(
                    ex.nome.trim().toLowerCase(),
                  ),
                  lastWeight:
                      lastWeights[_effectiveFor(ex).nome.trim().toLowerCase()],
                  lastObservation:
                      lastObservations[_effectiveFor(
                        ex,
                      ).nome.trim().toLowerCase()],
                  dayName: today.dayName,
                  onSwap: () => _handleSwapExercise(ex),
                  onStart: (eff, lastW, lastObs, day) => _handleStartExercise(
                    ex,
                    eff,
                    lastW,
                    lastObs,
                    day,
                    exercises,
                  ),
                ),
              if (finished.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showFinished = !_showFinished),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
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
                              ? l.hideCompleted(finished.length)
                              : l.showCompleted(finished.length),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
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
                      isSwapped: _sessionSwaps.containsKey(
                        ex.nome.trim().toLowerCase(),
                      ),
                      lastWeight:
                          lastWeights[_effectiveFor(
                            ex,
                          ).nome.trim().toLowerCase()],
                      lastObservation:
                          lastObservations[_effectiveFor(
                            ex,
                          ).nome.trim().toLowerCase()],
                      dayName: today.dayName,
                      onSwap: () => _handleSwapExercise(ex),
                      onStart: (eff, lastW, lastObs, day) =>
                          _handleStartExercise(
                            ex,
                            eff,
                            lastW,
                            lastObs,
                            day,
                            exercises,
                          ),
                    ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l.errLoadTodayWorkout)),
      ),
      floatingActionButton:
          _cacheReady &&
              ref.read(workoutSessionCacheProvider).activeId != null &&
              todayAsync.asData?.value != null &&
              !todayAsync.value!.isRest &&
              todayAsync.value!.exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!_cacheReady ||
                    ref.read(workoutSessionCacheProvider).activeId == null) {
                  return;
                }
                final today = todayAsync.value!;
                final exercises = _cachedExercises ?? today.exercises;
                final timerStates = {
                  for (final ex in exercises)
                    ex.nome: ref.read(
                      restTimerProvider((
                        _effectiveFor(ex).nome,
                        parseRestSeconds(_effectiveFor(ex).descanso),
                        parseSetsCount(_effectiveFor(ex).series),
                      )),
                    ),
                };
                final allDone =
                    exercises.isNotEmpty &&
                    exercises.every((e) => timerStates[e.nome]!.finished);
                _confirmFinish(exercises, today.dayName, allDone);
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.emoji_events),
              label: Text(l.btnFinishWorkout),
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
  final void Function(
    WorkoutExercise effective,
    String? lastWeight,
    String? lastObservation,
    String? dayName,
  )
  onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSeconds = parseRestSeconds(effectiveExercise.descanso);
    final totalSets = parseSetsCount(effectiveExercise.series);
    final timerState = ref.watch(
      restTimerProvider((effectiveExercise.nome, totalSeconds, totalSets)),
    );
    final finished = timerState.finished;
    final inProgress = !finished && timerState.completedSets > 0;
    final isCardio =
        effectiveExercise.modeloDeTreino?.toLowerCase() == 'cardio';
    final imageBytes = ref
        .watch(exerciseImageProvider(effectiveExercise.nome))
        .asData
        ?.value;

    Color? cardColor;
    if (finished) {
      cardColor = Theme.of(context).brightness == Brightness.dark
          ? Color.alphaBlend(
              Colors.green.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.surfaceContainer,
            )
          : const Color(0xFFE8F5E9);
    } else if (inProgress) {
      cardColor = const Color(0xFFFFF3E0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            onStart(effectiveExercise, lastWeight, lastObservation, dayName),
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
                                  Text(
                                    effectiveExercise.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isSwapped)
                                    Text(
                                      context.l10n.exerciseSwapped(
                                        exercise.nome,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (finished)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      context.l10n.exerciseCompleted,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (inProgress)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCardio
                                      ? context.l10n.exerciseRunning
                                      : context.l10n.exerciseSetsProgress(
                                          timerState.completedSets,
                                          totalSets,
                                        ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                              if (effectiveExercise.repeticoes != null)
                                _Stat(
                                  context.l10n.statGoal,
                                  effectiveExercise.repeticoes!,
                                ),
                              if (finished)
                                _Stat(context.l10n.statTime, timerState.weight),
                              _Stat(
                                context.l10n.statLastTime,
                                lastWeight ?? '—',
                              ),
                            ] else ...[
                              if (effectiveExercise.series != null)
                                _Stat(
                                  context.l10n.statSets,
                                  effectiveExercise.series!,
                                ),
                              if (effectiveExercise.repeticoes != null)
                                _Stat(
                                  context.l10n.statReps,
                                  effectiveExercise.repeticoes!,
                                ),
                              if (effectiveExercise.descanso != null)
                                _Stat(
                                  context.l10n.statRest,
                                  effectiveExercise.descanso!,
                                ),
                              _Stat(
                                context.l10n.statLastWeight,
                                lastWeight != null ? '$lastWeight kg' : '—',
                              ),
                              if (lastObservation != null &&
                                  lastObservation!.isNotEmpty)
                                _Stat(
                                  context.l10n.statLastObs,
                                  lastObservation!,
                                ),
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
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  if (finished) ...[
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: context.l10n.editExerciseLabel,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => onStart(
                        effectiveExercise,
                        lastWeight,
                        lastObservation,
                        dayName,
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: context.l10n.cancelCompletedExerciseLabel,
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () async {
                        final l = context.l10n;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l.cancelCompletedExerciseLabel),
                            content: Text(l.cancelCompletedExerciseMessage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l.cancelar),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l.sim),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        final cache = ref.read(workoutSessionCacheProvider);
                        try {
                          await cache.ignoreNative(effectiveExercise.nome);
                          ref
                              .read(
                                restTimerProvider((
                                  effectiveExercise.nome,
                                  totalSeconds,
                                  totalSets,
                                )).notifier,
                              )
                              .resetForNewSession();
                          await cache.flush();
                          await ref
                              .read(workoutLiveProvider.notifier)
                              .resetCompleted(effectiveExercise.nome);
                          await cache.allowNative(effectiveExercise.nome);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.genericError)),
                            );
                          }
                        }
                      },
                    ),
                  ],
                  _ActionButton(
                    icon: Icons.search,
                    label: context.l10n.btnVideos,
                    color: const Color(0xFF2196F3),
                    onPressed: () => showExerciseVideoSheet(
                      context,
                      exerciseName: effectiveExercise.nome,
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz,
                    label: context.l10n.btnSwap,
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
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

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
            Icon(
              icon,
              color: onPressed != null ? color : Colors.grey,
              size: 26,
            ),
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
