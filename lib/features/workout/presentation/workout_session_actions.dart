import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../home/data/app_api.dart';
import '../../home/state/today_workout_override.dart';
import '../state/active_workout_session.dart';
import '../state/workout_live_activity.dart';
import '../state/workout_session_cache.dart';
import 'rest_timer_screen.dart';

Future<bool> cancelWorkoutSession(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.cancelWorkoutLabel),
      content: Text(l.cancelWorkoutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.cancelWorkoutLabel),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await ref.read(workoutSessionCacheProvider).cancel();
    await ref.read(workoutLiveProvider.notifier).end();
    ref.invalidate(restTimerProvider);
    ref.read(activeWorkoutSessionProvider.notifier).state = null;
    ref.read(todayDayOverrideProvider.notifier).state = null;
    ref.invalidate(effectiveTodayWorkoutProvider);
    ref.invalidate(lastWorkoutProvider);
    ref.invalidate(workoutHistoryProvider);
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.genericError)));
    }
    return false;
  }
}
