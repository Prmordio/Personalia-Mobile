import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Treino do dia já começado (primeira série iniciada no cronômetro). A Home mostra
/// "Continuar treino" em vez de "Iniciar treino". Vale só para a data em que começou.
class ActiveWorkoutSession {
  const ActiveWorkoutSession({required this.dayName, required this.startedAt});
  final String dayName;
  final DateTime startedAt;

  bool isFor(String dayName, DateTime now) =>
      this.dayName == dayName &&
      startedAt.year == now.year &&
      startedAt.month == now.month &&
      startedAt.day == now.day;
}

final activeWorkoutSessionProvider = StateProvider<ActiveWorkoutSession?>((ref) => null);
