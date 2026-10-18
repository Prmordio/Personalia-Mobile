import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horário de início da sessão. O cache mantém o treino ativo até concluir
/// ou cancelar; isFor também permite consultas limitadas ao dia de início.
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

final activeWorkoutSessionProvider = StateProvider<ActiveWorkoutSession?>(
  (ref) => null,
);
