import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletedWorkoutSession {
  const CompletedWorkoutSession({
    required this.dayName,
    required this.completedAt,
    required this.duration,
    required this.completedCount,
    required this.totalCount,
  });
  final String dayName;
  final DateTime completedAt;
  final Duration duration;
  final int completedCount;
  final int totalCount;

  bool isToday() {
    final now = DateTime.now();
    return completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;
  }

  String get durationFormatted {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }
}

final completedWorkoutSessionProvider = StateProvider<CompletedWorkoutSession?>((ref) => null);
