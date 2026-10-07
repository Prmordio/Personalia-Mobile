import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/rest_alarm.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/app_api.dart';
import '../data/exercise_image_provider.dart';
import '../state/active_workout_session.dart';
import 'swap_exercise_screen.dart';
import 'widgets/exercise_list.dart';
import 'widgets/exercise_video_sheet.dart';

int parseRestSeconds(String? descanso, {int fallback = 60}) {
  if (descanso == null || descanso.trim().isEmpty) return fallback;
  final match = RegExp(r'(\d+)').firstMatch(descanso);
  if (match == null) return fallback;
  final value = int.tryParse(match.group(1)!) ?? fallback;
  final isMinutes = descanso.toLowerCase().contains('min');
  return isMinutes ? value * 60 : value;
}

/// Duração alvo do cardio (de "10 min", "30 min", "45min", "3600" etc.) em segundos.
int parseCardioDuration(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 0;
  final match = RegExp(r'(\d+)').firstMatch(raw);
  if (match == null) return 0;
  final value = int.tryParse(match.group(1)!) ?? 0;
  final isMinutes = raw.toLowerCase().contains('min');
  return isMinutes ? value * 60 : value;
}

int parseSetsCount(String? series, {int fallback = 1}) {
  if (series == null || series.trim().isEmpty) return fallback;
  final match = RegExp(r'(\d+)').firstMatch(series);
  if (match == null) return fallback;
  return int.tryParse(match.group(1)!) ?? fallback;
}

class RestTimerArgs {
  const RestTimerArgs({required this.exercise, this.lastWeight, this.dayName});
  final WorkoutExercise exercise;
  final String? lastWeight;

  /// Dia do plano em andamento (para a Home mostrar "Continuar treino").
  final String? dayName;
}

class RestTimerState {
  const RestTimerState({
    required this.remaining,
    required this.completedSets,
    required this.running,
    this.weight = '',
    this.observation = '',
    this.finished = false,
    this.elapsed = 0,
  });
  final int remaining;
  final int completedSets;
  final bool running;
  final String weight;
  final String observation;
  final bool finished;
  final int elapsed;

  RestTimerState copyWith({
    int? remaining,
    int? completedSets,
    bool? running,
    String? weight,
    String? observation,
    bool? finished,
    int? elapsed,
  }) =>
      RestTimerState(
        remaining: remaining ?? this.remaining,
        completedSets: completedSets ?? this.completedSets,
        running: running ?? this.running,
        weight: weight ?? this.weight,
        observation: observation ?? this.observation,
        finished: finished ?? this.finished,
        elapsed: elapsed ?? this.elapsed,
      );
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier({
    required this.totalSeconds,
    required this.totalSets,
    this.exerciseName = '',
    this.alarm,
    this.onSetStarted,
  }) : super(RestTimerState(remaining: totalSeconds, completedSets: 0, running: false));

  final int totalSeconds;
  final int totalSets;
  final String exerciseName;

  /// Aviso de fim do descanso (notificação com som). Agendado ao iniciar, reagendado no +15s
  /// e cancelado ao pausar/reiniciar — assim toca mesmo com o app em segundo plano.
  final RestAlarm? alarm;

  /// Chamado quando uma série começa (marca o treino do dia como em andamento).
  final void Function()? onSetStarted;
  Timer? _timer;

  /// Momento exato em que o descanso deve terminar. Usado para cálculo baseado em
  /// DateTime real — evita drift do Timer.periodic e dessincronia com o segundo plano.
  DateTime? _endTime;

  int get alarmId => exerciseName.hashCode & 0x7fffffff;

  void toggle() {
    // Exercício sem descanso: marca a série imediatamente sem iniciar temporizador.
    if (totalSeconds == 0) {
      if (state.completedSets < totalSets) {
        state = state.copyWith(completedSets: state.completedSets + 1);
        onSetStarted?.call();
      }
      return;
    }

    if (state.remaining <= 0) return;
    if (state.running) {
      _timer?.cancel();
      _endTime = null;
      state = state.copyWith(running: false);
      alarm?.cancel(alarmId);
      return;
    }
    final isFreshStart = state.remaining == totalSeconds;
    state = state.copyWith(
      running: true,
      completedSets: isFreshStart && state.completedSets < totalSets ? state.completedSets + 1 : state.completedSets,
    );
    if (isFreshStart) onSetStarted?.call();
    _endTime = DateTime.now().add(Duration(seconds: state.remaining));
    alarm?.schedule(id: alarmId, after: Duration(seconds: state.remaining), exerciseName: exerciseName);
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Preferência pelo relógio real (evita drift). Em testes, DateTime.now() não é
      // mockado pelo FakeAsync do testWidgets, então clockRemaining fica em ~totalSeconds;
      // clamp a state.remaining-1 garante pelo menos 1s de progresso por tick.
      final clockRemaining = _endTime != null
          ? _endTime!.difference(DateTime.now()).inSeconds
          : state.remaining - 1;
      final remaining = clockRemaining.clamp(0, state.remaining - 1);
      if (remaining <= 0) {
        timer.cancel();
        _endTime = null;
        state = state.copyWith(remaining: 0, running: false);
        // App aberto: avisa na hora (mesmo id da agendada — uma substitui a outra).
        alarm?.cancel(alarmId);
        alarm?.fireNow(id: alarmId, exerciseName: exerciseName);
        return;
      }
      state = state.copyWith(remaining: remaining);
    });
  }

  /// Reconecta o timer ao tempo real após o app retornar do segundo plano ou
  /// após reentrada na tela enquanto o cronômetro estava rodando.
  void syncOnResume() {
    if (!state.running || _endTime == null) return;
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      _endTime = null;
      state = state.copyWith(remaining: 0, running: false);
      alarm?.cancel(alarmId);
      alarm?.fireNow(id: alarmId, exerciseName: exerciseName);
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  void addSeconds(int seconds) {
    final newRemaining = state.remaining + seconds;
    state = state.copyWith(remaining: newRemaining);
    if (state.running && _endTime != null) {
      _endTime = _endTime!.add(Duration(seconds: seconds));
      alarm?.schedule(id: alarmId, after: Duration(seconds: newRemaining), exerciseName: exerciseName);
    }
  }

  void reset() {
    _timer?.cancel();
    _endTime = null;
    state = state.copyWith(remaining: totalSeconds, running: false);
    alarm?.cancel(alarmId);
  }

  /// Confirma a última série sem iniciar mais um cronômetro (N séries = N-1 descansos).
  void confirmLastSet() {
    state = state.copyWith(completedSets: totalSets);
  }

  void setWeight(String value) => state = state.copyWith(weight: value);
  void setObservation(String value) => state = state.copyWith(observation: value);

  // Campos internos do cardio — não persistem no estado, são auxiliares do Timer.
  DateTime? _cardioStartTime;
  int _cardioElapsedAtStart = 0;
  int _cardioTargetSeconds = 0;
  bool _cardioGoalFired = false;

  void toggleCardio({int targetSeconds = 0}) {
    if (state.running) {
      _timer?.cancel();
      _cardioElapsedAtStart = state.elapsed;
      _cardioStartTime = null;
      alarm?.cancel(alarmId);
      state = state.copyWith(running: false);
      return;
    }
    if (state.elapsed == 0) {
      state = state.copyWith(running: true, completedSets: 1);
      onSetStarted?.call();
    } else {
      state = state.copyWith(running: true);
    }
    _cardioStartTime = DateTime.now();
    _cardioElapsedAtStart = state.elapsed;
    _cardioTargetSeconds = targetSeconds;

    // Agenda notificação push quando atingir a duração alvo.
    if (targetSeconds > 0 && state.elapsed < targetSeconds) {
      final remaining = targetSeconds - state.elapsed;
      alarm?.schedule(id: alarmId, after: Duration(seconds: remaining), exerciseName: exerciseName);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed = _cardioElapsedAtStart + DateTime.now().difference(_cardioStartTime!).inSeconds;

      // Dispara notificação no app quando atingir o tempo alvo (app em primeiro plano).
      if (_cardioTargetSeconds > 0 && !_cardioGoalFired && newElapsed >= _cardioTargetSeconds) {
        _cardioGoalFired = true;
        alarm?.cancel(alarmId);
        alarm?.fireNow(id: alarmId, exerciseName: exerciseName);
      }

      state = state.copyWith(elapsed: newElapsed);
    });
  }

  void stopCardio() {
    _timer?.cancel();
    _cardioStartTime = null;
    alarm?.cancel(alarmId);
    final e = state.elapsed;
    final m = (e ~/ 60).toString().padLeft(2, '0');
    final s = (e % 60).toString().padLeft(2, '0');
    // Armazena o tempo percorrido no campo weight para registro no log do treino.
    state = state.copyWith(running: false, weight: '$m:$s', finished: true);
  }

  void resetForNewSession() {
    _timer?.cancel();
    _endTime = null;
    _cardioStartTime = null;
    _cardioElapsedAtStart = 0;
    _cardioGoalFired = false;
    alarm?.cancel(alarmId);
    state = RestTimerState(remaining: totalSeconds, completedSets: 0, running: false, elapsed: 0);
  }

  void finish() {
    _timer?.cancel();
    _endTime = null;
    alarm?.cancel(alarmId);
    state = state.copyWith(running: false, finished: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Chave: nome do exercício + descanso/séries (identifica o exercício de hoje). Provider
/// sem autoDispose de propósito — o cronômetro (e o Timer por trás dele) precisa sobreviver
/// à navegação pra fora da tela e voltar, em vez de reiniciar a cada vez.
final restTimerProvider =
    StateNotifierProvider.family<RestTimerNotifier, RestTimerState, (String, int, int)>((ref, key) {
  final (exerciseName, totalSeconds, totalSets) = key;
  return RestTimerNotifier(
    totalSeconds: totalSeconds,
    totalSets: totalSets,
    exerciseName: exerciseName,
    alarm: ref.read(restAlarmProvider),
  );
});

class RestTimerScreen extends ConsumerStatefulWidget {
  const RestTimerScreen({super.key, required this.args});

  final RestTimerArgs args;

  @override
  ConsumerState<RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends ConsumerState<RestTimerScreen> with WidgetsBindingObserver {
  late final TextEditingController _weightController;
  late final TextEditingController _observationController;

  (String, int, int) get _key {
    final exercise = widget.args.exercise;
    return (exercise.nome, parseRestSeconds(exercise.descanso), parseSetsCount(exercise.series));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final current = ref.read(restTimerProvider(_key));
    _weightController = TextEditingController(text: current.weight);
    _observationController = TextEditingController(text: current.observation);
    // Sincroniza o tempo real ao reentrar na tela (ex: voltou do 2° plano ou de outra tela).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restTimerProvider(_key).notifier).syncOnResume();
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

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _ensureSession(WidgetRef ref, String? dayName) {
    if (dayName != null && ref.read(activeWorkoutSessionProvider) == null) {
      ref.read(activeWorkoutSessionProvider.notifier).state =
          ActiveWorkoutSession(dayName: dayName, startedAt: DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final exercise = args.exercise;
    final key = _key;
    final totalSeconds = key.$2;
    final totalSets = key.$3;
    final state = ref.watch(restTimerProvider(key));
    final notifier = ref.read(restTimerProvider(key).notifier);
    // Usa o mesmo detector de cardio da lista de exercícios: nome + "min" em repetições.
    final isCardio = isCardioExercise(exercise);

    if (isCardio) {
      return _buildCardioScreen(context, exercise, state, notifier);
    }

    final done = state.remaining <= 0;
    // N séries = N-1 descansos. Após o último descanso, o usuário ainda faz a série final
    // sem mais cronômetro — lastSetReady indica esse momento.
    final allSetsDone = totalSets <= 1 ? state.completedSets >= 1 : state.completedSets >= totalSets - 1;
    final lastSetReady = allSetsDone && done && state.completedSets < totalSets;
    final allFinished = state.completedSets >= totalSets;

    final imageBytes = ref.watch(exerciseImageProvider(exercise.nome)).asData?.value;

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
              if (exercise.series != null) _Stat('Séries', exercise.series!),
              if (exercise.repeticoes != null) _Stat('Repetições', exercise.repeticoes!),
              if (exercise.descanso != null) _Stat('Descanso', exercise.descanso!),
              _Stat('Último peso', args.lastWeight != null ? '${args.lastWeight} kg' : '—'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                onPressed: () async {
                  final alt = await Navigator.of(context).push<ExerciseAlternative>(
                    MaterialPageRoute(
                      builder: (_) => SwapExerciseScreen(args: SwapExerciseArgs(exercise: exercise)),
                    ),
                  );
                  if (alt != null) {
                    notifier.resetForNewSession();
                    // Reinicia o timer com o exercício trocado; navega de volta para a tela
                    // de detalhe e abre a nova tela de timer para o exercício alternativo.
                    if (context.mounted) Navigator.of(context).pop(alt);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= totalSets; i++) ...[
                _SetIndicator(index: i, done: i <= state.completedSets),
                if (i != totalSets) const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: totalSeconds == 0 ? 1 : 1 - (state.remaining / totalSeconds),
                  strokeWidth: 10,
                  color: done ? Colors.green : AppColors.orange,
                  backgroundColor: AppColors.background,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    done ? 'Pronto!' : _format(state.remaining),
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    iconSize: 56,
                    color: allFinished
                        ? Colors.green
                        : lastSetReady
                            ? Colors.green
                            : AppColors.orange,
                    icon: Icon(
                      allFinished
                          ? Icons.check_circle
                          : lastSetReady
                              ? Icons.flag_circle
                              : done
                                  ? Icons.replay_circle_filled
                                  : (state.running ? Icons.pause_circle_filled : Icons.play_circle_fill),
                    ),
                    onPressed: allFinished
                        ? null
                        : lastSetReady
                            ? () => notifier.confirmLastSet()
                            : done
                                ? () {
                                    // Reset + inicia próxima série em um único toque.
                                    notifier.reset();
                                    _ensureSession(ref, args.dayName);
                                    notifier.toggle();
                                  }
                                : () {
                                    _ensureSession(ref, args.dayName);
                                    notifier.toggle();
                                  },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () => notifier.addSeconds(15), child: const Text('+15s')),
              const SizedBox(width: 12),
              TextButton(onPressed: notifier.reset, child: const Text('Reiniciar')),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: state.finished ? Colors.green.shade600 : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(state.finished ? Icons.check_circle : Icons.flag),
              label: Text(
                state.finished
                    ? 'Exercício concluído!'
                    : state.weight.trim().isEmpty
                        ? 'Digite o peso para finalizar'
                        : 'Finalizar exercício',
              ),
              onPressed: state.finished || state.weight.trim().isEmpty
                  ? null
                  : () {
                      notifier.finish();
                      Navigator.of(context).pop();
                    },
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso utilizado (kg)',
              prefixIcon: Icon(Icons.fitness_center),
              border: OutlineInputBorder(),
            ),
            onChanged: notifier.setWeight,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observationController,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: notifier.setObservation,
          ),
          const SizedBox(height: 24),
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

    final Color progressColor = goalReached || state.finished ? Colors.green : AppColors.orange;

    String statusLabel;
    if (state.finished) {
      statusLabel = 'Concluído! ✅';
    } else if (goalReached) {
      statusLabel = 'Meta atingida! 🎉';
    } else if (state.running) {
      statusLabel = 'Em execução';
    } else {
      statusLabel = state.elapsed == 0 ? 'Toque para iniciar' : 'Pausado';
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
              if (exercise.repeticoes != null) _Stat('Duração', exercise.repeticoes!),
              if (widget.args.lastWeight != null) _Stat('Último tempo', widget.args.lastWeight!),
            ],
          ),
          const SizedBox(height: 8),
          // Botões Vídeos e Trocar (mesmo padrão da tela de musculação).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                onPressed: () async {
                  final alt = await Navigator.of(context).push<ExerciseAlternative>(
                    MaterialPageRoute(
                      builder: (_) => SwapExerciseScreen(args: SwapExerciseArgs(exercise: exercise)),
                    ),
                  );
                  if (alt != null) {
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
                  backgroundColor: AppColors.background,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatElapsed(state.elapsed),
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                  ),
                  Text(statusLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (!state.finished)
                    IconButton(
                      iconSize: 56,
                      color: goalReached ? Colors.green : AppColors.orange,
                      icon: Icon(state.running ? Icons.pause_circle_filled : Icons.play_circle_fill),
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
                backgroundColor: state.finished ? Colors.green.shade600 : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(state.finished ? Icons.check_circle : Icons.flag),
              label: Text(
                state.finished ? 'Cardio concluído!' : 'Finalizar cardio',
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
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

class _SetIndicator extends StatelessWidget {
  const _SetIndicator({required this.index, required this.done});
  final int index;
  final bool done;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return const Icon(Icons.highlight_off, size: 32, color: AppColors.orange);
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: Text('$index', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
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
