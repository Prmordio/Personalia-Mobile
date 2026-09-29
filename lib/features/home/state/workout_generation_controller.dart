import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_api.dart';

/// - requesting: aguardando a resposta do POST /app/workout/generate;
/// - generating: backend aceitou — consultando o treino até ele aparecer;
/// - failed: o backend avisou que a geração terminou sem treino (ex.: falha no agente);
/// - timedOut: passou do tempo normal sem aparecer (o treino ainda pode chegar depois).
enum WorkoutGenerationStatus { idle, requesting, generating, failed, timedOut }

enum GenerateOutcome { started, subscriptionRequired, alreadyRunning, failed }

/// Mantém o "Gerar meu treino" travado do clique até o treino ficar pronto — mesmo trocando
/// de aba (provider não é autoDispose). Usa polling em vez de websocket: é um evento único
/// de 1–2 min, e o polling já passa pelo gateway sem infraestrutura extra.
class WorkoutGenerationController extends StateNotifier<WorkoutGenerationStatus> {
  WorkoutGenerationController(
    this._api, {
    required this.onWorkoutReady,
    this.pollInterval = const Duration(seconds: 3),
    // ~10 min: com o modelo local a geração já levou ~5 min (o backend guarda o status por 10).
    this.maxPollAttempts = 200,
  }) : super(WorkoutGenerationStatus.idle);

  final AppApi _api;
  final void Function() onWorkoutReady;
  final Duration pollInterval;
  final int maxPollAttempts;

  bool get isBusy =>
      state == WorkoutGenerationStatus.requesting || state == WorkoutGenerationStatus.generating;

  Future<GenerateOutcome> generate() async {
    if (isBusy) return GenerateOutcome.alreadyRunning;

    state = WorkoutGenerationStatus.requesting;
    final bool started;
    try {
      started = await _api.generateWorkout();
    } catch (_) {
      if (mounted) state = WorkoutGenerationStatus.idle;
      return GenerateOutcome.failed;
    }
    if (!mounted) return GenerateOutcome.failed;

    if (!started) {
      state = WorkoutGenerationStatus.idle;
      return GenerateOutcome.subscriptionRequired;
    }

    state = WorkoutGenerationStatus.generating;
    unawaited(_pollUntilReady());
    return GenerateOutcome.started;
  }

  /// "Verificar novamente" depois do timeout — só consulta, não dispara outra geração.
  Future<void> checkAgain() async {
    if (isBusy) return;
    state = WorkoutGenerationStatus.generating;
    await _pollUntilReady();
  }

  Future<void> _pollUntilReady() async {
    for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
      await Future.delayed(pollInterval);
      if (!mounted) return;
      try {
        if (await _hasWorkout()) return;
        final status = await _api.getGenerationStatus();
        if (!mounted) return;
        // 'idle' sem treino: o status foi limpo — confirma o treino de novo antes de desistir
        // (ele pode ter sido salvo entre as duas consultas).
        if (status == 'failed' || (status == 'idle' && !await _hasWorkout())) {
          if (mounted && state == WorkoutGenerationStatus.generating) state = WorkoutGenerationStatus.failed;
          return;
        }
        if (!mounted || state != WorkoutGenerationStatus.generating) return;
      } catch (_) {
        // Erro transitório de rede não interrompe a espera.
      }
    }
    if (mounted) state = WorkoutGenerationStatus.timedOut;
  }

  /// true (e libera o botão) se o treino já apareceu.
  Future<bool> _hasWorkout() async {
    if (await _api.getCurrentWorkout() == null) return false;
    if (mounted) {
      state = WorkoutGenerationStatus.idle;
      onWorkoutReady();
    }
    return true;
  }
}

final workoutGenerationProvider =
    StateNotifierProvider<WorkoutGenerationController, WorkoutGenerationStatus>((ref) {
  return WorkoutGenerationController(
    ref.watch(appApiProvider),
    onWorkoutReady: () {
      ref.invalidate(currentWorkoutProvider);
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(progressProvider);
    },
  );
});
