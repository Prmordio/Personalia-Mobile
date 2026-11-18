import '../state/rest_timer_controller.dart';
import '../state/workout_session_cache.dart';
import '../state/workout_live_labels.dart';
import '../../../core/telemetry/app_telemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../execution_analysis/presentation/execution_capture_screen.dart';
import '../../execution_analysis/state/execution_analysis_controller.dart';
import '../../home/data/app_api.dart';
import '../data/exercise_image_provider.dart';
import '../state/active_workout_session.dart';
import '../state/workout_live_activity.dart';
import 'widgets/workout_execution_controls.dart';
import 'swap_exercise_screen.dart';
import 'widgets/exercise_list.dart';
import 'widgets/workout_action_button.dart';
import 'widgets/exercise_video_sheet.dart';

class RestTimerArgs {
  const RestTimerArgs({
    required this.exercise,
    this.lastWeight,
    this.lastObservation,
    this.dayName,
    this.upcomingExercises = const [],
  });
  final WorkoutExercise exercise;
  final List<WorkoutExercise> upcomingExercises;
  final String? lastWeight;
  final String? lastObservation;

  /// Dia do plano em andamento (para a Home mostrar "Continuar treino").
  final String? dayName;
}

class RestTimerScreen extends ConsumerStatefulWidget {
  const RestTimerScreen({super.key, required this.args});

  final RestTimerArgs args;

  @override
  ConsumerState<RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends ConsumerState<RestTimerScreen>
    with WidgetsBindingObserver {
  late final bool _recordOnly;
  late final TextEditingController _weightController;
  late final TextEditingController _observationController;

  (String, int, int) get _key {
    final exercise = widget.args.exercise;
    return (
      exercise.nome,
      parseRestSeconds(exercise.descanso),
      parseSetsCount(exercise.series),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final current = ref.read(restTimerProvider(_key));
    _recordOnly = current.finished;
    _weightController = TextEditingController(text: current.weight);
    _observationController = TextEditingController(text: current.observation);
    // Sincroniza o tempo real ao reentrar na tela (ex: voltou do 2° plano ou de outra tela).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _recordOnly) return;
      final cache = ref.read(workoutSessionCacheProvider);
      if (cache.ignoresNative(widget.args.exercise.nome)) {
        await ref
            .read(workoutLiveProvider.notifier)
            .resetCompleted(widget.args.exercise.nome);
        if (!mounted) return;
        await cache.allowNative(widget.args.exercise.nome);
        if (!mounted) return;
      }
      ref.read(restTimerProvider(_key).notifier).syncOnResume();
      if (!isCardioExercise(widget.args.exercise)) {
        final queue = [widget.args.exercise, ...widget.args.upcomingExercises];
        ref
            .read(workoutLiveProvider.notifier)
            .prepare(
              day: widget.args.dayName ?? '',
              startedAt: ref.read(activeWorkoutSessionProvider)?.startedAt,
              labels: workoutLiveLabels(context.l10n),
              weights: {
                for (final e in queue)
                  e.nome: ref
                      .read(
                        restTimerProvider(restTimerKeyFor(e)),
                      )
                      .weight,
              },
              completed: queue
                  .map(
                    (e) => ref
                        .read(
                          restTimerProvider(restTimerKeyFor(e)),
                        )
                        .completedSets,
                  )
                  .toList(),
              exercises: queue
                  .map(
                    (e) => <String, dynamic>{
                      'name': e.nome,
                      'sets': parseSetsCount(e.series),
                      'reps': e.repeticoes ?? '',
                      'restSeconds': parseRestSeconds(e.descanso),
                    },
                  )
                  .toList(),
            );
      } else {
        ref.read(workoutLiveProvider.notifier).end();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(restTimerProvider(_key).notifier).syncOnResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weightController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _ensureSession(WidgetRef ref, String? dayName) {
    if (dayName != null && ref.read(activeWorkoutSessionProvider) == null) {
      AppTelemetry.instance.event('workout_started');
      ref.read(activeWorkoutSessionProvider.notifier).state =
          ActiveWorkoutSession(dayName: dayName, startedAt: DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final exercise = args.exercise;
    final key = _key;
    final state = ref.watch(restTimerProvider(key));
    final notifier = ref.read(restTimerProvider(key).notifier);
    final isCardio = isCardioExercise(exercise);

    if (isCardio) {
      return _buildCardioScreen(context, exercise, state, notifier);
    }

    ref.listen<WorkoutLiveState?>(workoutLiveProvider, (previous, next) {
      if (_recordOnly ||
          next == null ||
          previous == null ||
          previous.name != exercise.nome ||
          next.name == exercise.nome ||
          previous.data['id'] != next.data['id']) {
        return;
      }
      final queue = [args.exercise, ...args.upcomingExercises];
      final index = queue.indexWhere((e) => e.nome == next.name);
      if (index < 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacement(
          '/workout/rest-timer',
          extra: RestTimerArgs(
            exercise: queue[index],
            dayName: args.dayName,
            upcomingExercises: queue.skip(index + 1).toList(),
          ),
        );
      });
    });

    final imageBytes = ref
        .watch(exerciseImageProvider(exercise.nome))
        .asData
        ?.value;
    final executionRuleKey = ref
        .watch(executionRuleCatalogProvider)
        .asData
        ?.value
        .match(exercise.nome);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.nome)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              if (exercise.series != null)
                WorkoutStat(context.l10n.restStatSeries, exercise.series!),
              if (exercise.repeticoes != null)
                WorkoutStat(context.l10n.restStatReps, exercise.repeticoes!),
              if (exercise.descanso != null)
                WorkoutStat(context.l10n.restStatRest, exercise.descanso!),
              WorkoutStat(
                context.l10n.restStatLastWeight,
                args.lastWeight != null ? '${args.lastWeight} kg' : '—',
              ),
              if (args.lastObservation != null &&
                  args.lastObservation!.isNotEmpty)
                WorkoutStat(context.l10n.restStatLastObs, args.lastObservation!),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WorkoutActionButton(
 horizontalPadding: 16,
                icon: Icons.search,
                label: context.l10n.restBtnVideos,
                color: const Color(0xFF2196F3),
                onPressed: () => showExerciseVideoSheet(
                  context,
                  exerciseName: exercise.nome,
                ),
              ),
              if (executionRuleKey case final ruleSetKey?)
                WorkoutActionButton(
 horizontalPadding: 16,
                  icon: Icons.videocam_outlined,
                  label: context.l10n.execBtnAnalyze,
                  color: AppColors.blue,
                  onPressed: () => context.push(
                    '/workout/execution-analysis',
                    extra: ExecutionCaptureArgs(exerciseKey: ruleSetKey, exerciseName: exercise.nome),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_recordOnly)
            WorkoutExecutionControls(
              exerciseName: exercise.nome,
              onStart: () => _ensureSession(ref, args.dayName),
            ),

          if (state.finished) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.restExerciseDone,
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          ...[
            // Chaves estáveis: o banner de "concluído" entra ACIMA dos campos quando o peso é
            // digitado; sem chave a lista casa os filhos por posição, recria o campo e o
            // teclado fecha no meio da digitação.
            TextField(
              key: const ValueKey('rest-weight-field'),
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.restWeightLabel,
                prefixIcon: const Icon(Icons.fitness_center),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                notifier.setWeight(value);
                ref
                    .read(workoutLiveProvider.notifier)
                    .recordWeight(exercise.nome, value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('rest-observation-field'),
              controller: _observationController,
              decoration: InputDecoration(
                labelText: context.l10n.restObservationLabel,
                prefixIcon: const Icon(Icons.notes),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: notifier.setObservation,
            ),
            const SizedBox(height: 8),
            if (state.weight.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.l10n.restWeightHint,
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.flag),
                label: Text(
                  context.l10n.restBtnFinishExercise,
                  style: const TextStyle(fontSize: 15),
                ),
                onPressed: state.weight.trim().isEmpty
                    ? null
                    : () {
                        if (!_recordOnly &&
                            ref.read(workoutLiveProvider)?.name ==
                                exercise.nome) {
                          ref.read(workoutLiveProvider.notifier).end();
                        }
                        notifier.finish();
                        Navigator.of(context).pop();
                      },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildCardioScreen(
    BuildContext context,
    WorkoutExercise exercise,
    RestTimerState state,
    RestTimerNotifier notifier,
  ) {
    final targetSeconds = parseCardioDuration(exercise.repeticoes);
    final goalReached = targetSeconds > 0 && state.elapsed >= targetSeconds;

    // Progresso: 0→1 do elapsed até o alvo; indeterminado se não há alvo.
    final double? progressValue = state.finished
        ? 1.0
        : targetSeconds > 0
        ? (state.elapsed / targetSeconds).clamp(0.0, 1.0)
        : (state.running ? null : 0.0);

    final Color progressColor = goalReached || state.finished
        ? Colors.green
        : AppColors.orange;

    final l = context.l10n;
    String statusLabel;
    if (state.finished) {
      statusLabel = l.restCardioDone;
    } else if (goalReached) {
      statusLabel = l.restCardioGoalReached;
    } else if (state.running) {
      statusLabel = l.restCardioRunning;
    } else {
      statusLabel = state.elapsed == 0
          ? l.restCardioTapToStart
          : l.restCardioPaused;
    }

    return Scaffold(
      appBar: AppBar(title: Text(exercise.nome)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Somente Duração (meta do cardio) e último tempo registrado.
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              if (exercise.repeticoes != null)
                WorkoutStat(l.statDuration, exercise.repeticoes!),
              if (widget.args.lastWeight != null)
                WorkoutStat(l.restCardioLastTime, widget.args.lastWeight!),
            ],
          ),
          const SizedBox(height: 8),
          // Botões Vídeos e Trocar (mesmo padrão da tela de musculação).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WorkoutActionButton(
 horizontalPadding: 16,
                icon: Icons.search,
                label: l.restBtnVideos,
                color: const Color(0xFF2196F3),
                onPressed: () => showExerciseVideoSheet(
                  context,
                  exerciseName: exercise.nome,
                ),
              ),
              WorkoutActionButton(
 horizontalPadding: 16,
                icon: Icons.swap_horiz,
                label: l.restBtnSwap,
                color: AppColors.orange,
                onPressed: () async {
                  final alt = await Navigator.of(context)
                      .push<ExerciseAlternative>(
                        MaterialPageRoute(
                          builder: (_) => SwapExerciseScreen(
                            args: SwapExerciseArgs(exercise: exercise),
                          ),
                        ),
                      );
                  if (alt != null) {
                    if (ref.read(workoutLiveProvider)?.name == exercise.nome) {
                      ref.read(workoutLiveProvider.notifier).end();
                    }
                    notifier.resetForNewSession();
                    if (context.mounted) Navigator.of(context).pop(alt);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: 10,
                  color: progressColor,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatElapsed(state.elapsed),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!state.finished)
                    IconButton(
                      iconSize: 56,
                      tooltip: state.running ? context.l10n.restPause : context.l10n.restResume,
                      color: goalReached ? Colors.green : AppColors.orange,
                      icon: Icon(
                        state.running
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      onPressed: () {
                        _ensureSession(ref, widget.args.dayName);
                        notifier.toggleCardio(targetSeconds: targetSeconds);
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: state.finished
                    ? Colors.green.shade600
                    : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(state.finished ? Icons.check_circle : Icons.flag),
              label: Text(
                state.finished ? l.restBtnCardioDone : l.restBtnFinishCardio,
                style: const TextStyle(fontSize: 15),
              ),
              onPressed: state.finished || state.elapsed == 0
                  ? null
                  : () {
                      notifier.stopCardio();
                      Navigator.of(context).pop();
                    },
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _observationController,
            decoration: InputDecoration(
              labelText: l.restObservationLabel,
              prefixIcon: const Icon(Icons.notes),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: notifier.setObservation,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
