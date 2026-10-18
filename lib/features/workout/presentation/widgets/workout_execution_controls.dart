import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../state/workout_live_activity.dart';

/// Original timer presentation, backed by the shared lock-screen session.
class WorkoutExecutionControls extends ConsumerWidget {
  const WorkoutExecutionControls({
    super.key,
    required this.onStart,
    required this.exerciseName,
  });
  final VoidCallback onStart;
  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(workoutLiveProvider);
    if (live == null) return const LinearProgressIndicator();
    if (live.name != exerciseName) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(context.l10n.restActiveRecord(live.name)),
      );
    }
    void act(String action) {
      if (action == 'rest') onStart();
      ref.read(workoutLiveProvider.notifier).action(action);
    }

    final resting = live.phase == 'rest';
    final completed = live.phase == 'done';
    final restSeconds = (live.exercise['restSeconds'] as num).toInt();
    final seconds = !resting && live.completed == 0
        ? restSeconds
        : live.seconds;
    final restEnded = resting && seconds == 0;
    final clock =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final color = restEnded || completed ? Colors.green : AppColors.orange;
    final progress = completed || restEnded
        ? 1.0
        : resting && restSeconds > 0
        ? (1 - seconds / restSeconds).clamp(0.0, 1.0)
        : 0.0;
    final status = completed
        ? context.l10n.restExerciseDone
        : resting
        ? (live.running
              ? context.l10n.restStatusRest
              : context.l10n.restStatusPaused)
        : live.completed > 0
        ? context.l10n.restNextSet
        : context.l10n.restBetweenSets;
    final centerAction = resting ? 'toggle' : 'rest';
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 1; i <= live.totalSets; i++)
              _SetIndicator(index: i, done: i <= live.completed),
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
                value: progress,
                strokeWidth: 10,
                color: color,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clock,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (!completed)
                  IconButton(
                    iconSize: 56,
                    color: color,
                    onPressed: () => act(centerAction),
                    icon: Icon(
                      restEnded
                          ? Icons.replay_circle_filled
                          : live.running
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                    ),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green, size: 56),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (resting) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => act('add'),
                child: const Text('+30 s'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => act('skip'),
                child: Text(context.l10n.restEndRest),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (completed && !live.hasWeight) ...[
          Text(
            context.l10n.restWeightHint,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        if (completed && live.hasNext) ...[
          Text(
            context.l10n.restNextNamed(
              live.exercises[live.index + 1]['name'] as String,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        if (!completed || live.hasNext) ...[
          _TimerAction(
            label: resting
                ? clock
                : completed
                ? context.l10n.restBtnNextExercise
                : context.l10n.restBtnStartRest,
            icon: resting
                ? (live.running ? Icons.pause : Icons.play_arrow)
                : Icons.timer_outlined,
            onTap: completed && !live.hasWeight
                ? null
                : () => act(
                    resting
                        ? 'toggle'
                        : completed
                        ? 'next'
                        : 'rest',
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ],
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
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimerAction extends StatelessWidget {
  const _TimerAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: onTap == null
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : AppColors.orange,
    borderRadius: BorderRadius.circular(14),
    elevation: 4,
    shadowColor: AppColors.orange.withValues(alpha: 0.35),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
