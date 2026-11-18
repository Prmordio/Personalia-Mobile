import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/rest_alarm.dart';
import '../../home/data/app_api.dart';
import 'workout_session_cache.dart';

/// Identifica o cronômetro de um exercício de hoje: nome + descanso (s) + total de séries.
typedef RestTimerKey = (String, int, int);

/// Chave do [restTimerProvider] a partir do exercício (efetivo, já com trocas aplicadas).
RestTimerKey restTimerKeyFor(WorkoutExercise exercise) =>
    (exercise.nome, parseRestSeconds(exercise.descanso), parseSetsCount(exercise.series));

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
  return (int.tryParse(match.group(1)!) ?? fallback).clamp(1, 100);
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

  Map<String, dynamic> toCache() => {
    'remaining': remaining,
    'completedSets': completedSets,
    'running': false,
    'weight': weight,
    'observation': observation,
    'finished': finished,
    'elapsed': elapsed,
  };
  factory RestTimerState.fromCache(Map<String, dynamic> data) => RestTimerState(
    remaining: (data['remaining'] as num?)?.toInt() ?? 0,
    completedSets: (data['completedSets'] as num?)?.toInt() ?? 0,
    running: false,
    weight: data['weight'] as String? ?? '',
    observation: data['observation'] as String? ?? '',
    finished:
        data['finished'] == true &&
        (data['weight'] as String? ?? '').trim().isNotEmpty,
    elapsed: (data['elapsed'] as num?)?.toInt() ?? 0,
  );

  RestTimerState copyWith({
    int? remaining,
    int? completedSets,
    bool? running,
    String? weight,
    String? observation,
    bool? finished,
    int? elapsed,
  }) => RestTimerState(
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
    RestTimerState? initialState,
  }) : super(
         initialState ??
             RestTimerState(
               remaining: totalSeconds,
               completedSets: 0,
               running: false,
             ),
       );

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
      completedSets: isFreshStart && state.completedSets < totalSets
          ? state.completedSets + 1
          : state.completedSets,
    );
    if (isFreshStart) onSetStarted?.call();
    _endTime = DateTime.now().add(Duration(seconds: state.remaining));
    alarm?.schedule(
      id: alarmId,
      after: Duration(seconds: state.remaining),
      exerciseName: exerciseName,
    );
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
      alarm?.schedule(
        id: alarmId,
        after: Duration(seconds: newRemaining),
        exerciseName: exerciseName,
      );
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

  void syncExecution(int completedSets, {bool finished = false}) {
    final isFinished =
        state.weight.trim().isNotEmpty && (state.finished || finished);
    if (state.completedSets == completedSets && state.finished == isFinished) {
      return;
    }
    state = state.copyWith(completedSets: completedSets, finished: isFinished);
  }

  void setWeight(String value) => state = state.copyWith(
    weight: value,
    finished: state.finished && value.trim().isNotEmpty,
  );
  void setObservation(String value) =>
      state = state.copyWith(observation: value);

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
      alarm?.schedule(
        id: alarmId,
        after: Duration(seconds: remaining),
        exerciseName: exerciseName,
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed =
          _cardioElapsedAtStart +
          DateTime.now().difference(_cardioStartTime!).inSeconds;

      // Dispara notificação no app quando atingir o tempo alvo (app em primeiro plano).
      if (_cardioTargetSeconds > 0 &&
          !_cardioGoalFired &&
          newElapsed >= _cardioTargetSeconds) {
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
    state = RestTimerState(
      remaining: totalSeconds,
      completedSets: 0,
      running: false,
      elapsed: 0,
    );
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
    StateNotifierProvider.family<RestTimerNotifier, RestTimerState, RestTimerKey>((ref, key) {
      final (exerciseName, totalSeconds, totalSets) = key;
      final cache = ref.read(workoutSessionCacheProvider);
      final stored = cache.record(key);
      final notifier = RestTimerNotifier(
        initialState: stored == null ? null : RestTimerState.fromCache(stored),
        totalSeconds: totalSeconds,
        totalSets: totalSets,
        exerciseName: exerciseName,
        alarm: ref.read(restAlarmProvider),
      );
      final cacheOwner = cache.owner;
      final cacheSession = cache.activeId;
      notifier.addListener((state) {
        if (cache.owner == cacheOwner && cache.activeId == cacheSession) {
          cache.capture(key, state.toCache());
        }
      }, fireImmediately: false);
      return notifier;
    });
