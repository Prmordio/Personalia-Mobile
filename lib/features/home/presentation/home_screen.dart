import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emoji_loader.dart';
import '../data/app_api.dart';
import '../../auth/presentation/biometric_offer_gate.dart';
import '../../workout/presentation/rest_timer_screen.dart';
import '../../workout/state/active_workout_session.dart';
import '../../workout/state/completed_workout_session.dart';
import '../state/today_workout_override.dart';
import '../state/workout_generation_controller.dart';
import 'subscription_checkout.dart';

final _dueDateFormat = DateFormat('dd/MM/yyyy');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(currentWorkoutProvider);
    final tipAsync = ref.watch(todayTipProvider);
    final todayWorkoutAsync = ref.watch(effectiveTodayWorkoutProvider);
    final progressAsync = ref.watch(progressProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return BiometricOfferGate(
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.homeAppBarTitle)),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentWorkoutProvider);
            ref.invalidate(todayTipProvider);
            ref.invalidate(todayWorkoutProvider);
            ref.invalidate(progressProvider);
            ref.invalidate(subscriptionProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              subscriptionAsync.when(
                data: (subscription) => _SubscriptionCard(
                  subscription: subscription,
                  onSubscribe: () => openSubscriptionCheckout(context, ref),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              workoutAsync.when(
                data: (workout) {
                  final isActive = subscriptionAsync.maybeWhen(
                    data: (s) => s.isValid,
                    orElse: () => true,
                  );
                  return workout == null
                      ? const _NoWorkoutCard()
                      : Column(
                          children: [
                            _StartWorkoutCard(
                              todayAsync: todayWorkoutAsync,
                              plan: workout,
                              isActive: isActive,
                            ),
                            const SizedBox(height: 16),
                            _ViewPlanCard(isActive: isActive),
                            const SizedBox(height: 16),
                            _ProgressCard(
                              progressAsync: progressAsync,
                              isActive: isActive,
                            ),
                            // Dica do dia já aberta, logo abaixo da evolução.
                            ...tipAsync.maybeWhen(
                              data: (tip) => tip.texto == null
                                  ? const <Widget>[]
                                  : [
                                      const SizedBox(height: 16),
                                      _TipCard(tip: tip),
                                    ],
                              orElse: () => const <Widget>[],
                            ),
                          ],
                        );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) =>
                    Text(context.l10n.errLoadWorkout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onSubscribe,
  });
  final SubscriptionInfo subscription;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final dueDate = subscription.dueDate;
    final dueDateLabel = dueDate != null
        ? _dueDateFormat.format(dueDate)
        : null;

    final l = context.l10n;
    String emoji;
    String title;
    String? subtitle;
    if (subscription.isFreeTrial) {
      emoji = '🎁';
      title = l.subscriptionFreeTrial;
      subtitle = dueDateLabel != null ? l.subscriptionValidUntil(dueDateLabel) : null;
    } else if (subscription.isValid) {
      emoji = '✅';
      title = l.subscriptionActive;
      subtitle = dueDateLabel != null ? l.subscriptionNextCharge(dueDateLabel) : null;
    } else {
      emoji = '⚠️';
      title = l.subscriptionInactive;
      subtitle = l.subscriptionSignupPrompt;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            ),
            if (!subscription.isValid)
              ElevatedButton(
                onPressed: onSubscribe,
                child: Text(l.subscriptionButton),
              ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final DailyTip tip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dailyTipTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(tip.texto ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoWorkoutCard extends ConsumerWidget {
  const _NoWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(workoutGenerationProvider);
    final controller = ref.read(workoutGenerationProvider.notifier);

    Future<void> generate() async {
      final locale = ref.read(localeProvider);
      final language = locale?.languageCode ?? 'pt';
      final outcome = await controller.generate(language: language);
      if (!context.mounted) return;
      switch (outcome) {
        case GenerateOutcome.subscriptionRequired:
          ref.invalidate(subscriptionProvider);
          await showSubscriptionRequiredDialog(context, ref);
        case GenerateOutcome.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errCannotStartGeneration)),
          );
        case GenerateOutcome.started:
        case GenerateOutcome.alreadyRunning:
          break;
      }
    }

    final l = context.l10n;
    final (
      String title,
      String? subtitle,
      String buttonLabel,
      VoidCallback? onPressed,
    ) = switch (status) {
      WorkoutGenerationStatus.idle => (
        l.noWorkoutIdleTitle,
        null,
        l.generateWorkoutButton,
        generate,
      ),
      WorkoutGenerationStatus.requesting => (
        l.noWorkoutIdleTitle,
        null,
        l.btnSendingRequest,
        null,
      ),
      WorkoutGenerationStatus.generating => (
        l.noWorkoutGeneratingTitle,
        l.noWorkoutGeneratingSubtitle,
        l.btnGenerating,
        null,
      ),
      WorkoutGenerationStatus.failed => (
        l.noWorkoutFailedTitle,
        l.noWorkoutFailedSubtitle,
        l.btnRetry,
        generate,
      ),
      WorkoutGenerationStatus.timedOut => (
        l.noWorkoutTimedOutTitle,
        l.noWorkoutTimedOutSubtitle,
        l.btnCheckAgain,
        controller.checkAgain,
      ),
    };
    final busy =
        status == WorkoutGenerationStatus.requesting ||
        status == WorkoutGenerationStatus.generating;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: busy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          // Botão desabilitado é cinza: spinner branco sumiria.
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(buttonLabel),
                      ],
                    )
                  : Text(buttonLabel),
            ),
            if (status == WorkoutGenerationStatus.generating) ...[
              const SizedBox(height: 20),
              const EmojiLoader(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartWorkoutCard extends ConsumerWidget {
  const _StartWorkoutCard({
    required this.todayAsync,
    required this.plan,
    this.isActive = true,
  });
  final AsyncValue<TodayWorkout> todayAsync;
  final CurrentWorkout plan;
  final bool isActive;

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  /// "Trocar treino": escolher outro dia do plano para treinar hoje (igual ao bot).
  Future<void> _chooseDay(BuildContext context, WidgetRef ref) async {
    final current = todayAsync.asData?.value.dayName;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                context.l10n.chooseWorkoutDayTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            for (final day in plan.days)
              ListTile(
                title: Text(day.dayName),
                subtitle: Text(context.l10n.exercisesCount(day.exercises.length)),
                trailing: day.dayName == current
                    ? const Icon(Icons.check, color: AppColors.orange)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(day.dayName),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == current) return;
    ref.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(
      dayName: chosen,
      date: DateTime.now(),
    );
    if (context.mounted) context.push('/workout/today');
  }

  void _resetAndTrainAgain(
    BuildContext context,
    WidgetRef ref,
    TodayWorkout today,
  ) {
    for (final ex in today.exercises) {
      final key = (
        ex.nome,
        parseRestSeconds(ex.descanso),
        parseSetsCount(ex.series),
      );
      ref.read(restTimerProvider(key).notifier).resetForNewSession();
    }

    // Prioriza a sessão concluída em memória (mais recente que o cache do lastWorkoutProvider).
    // Fallback: último treino do banco. Fallback final: o dia atual.
    final completedSession = ref.read(completedWorkoutSessionProvider);
    final lastWorkout = ref.read(lastWorkoutProvider).asData?.value;
    final lastDayName =
        completedSession?.dayName ?? lastWorkout?.dayName ?? today.dayName;

    // Filtra dias de descanso para não entrar na rotação A → Descanso → B.
    final nonRestDays = plan.days
        .where((d) => !d.dayName.toLowerCase().contains('descanso'))
        .toList();
    final days = nonRestDays.isNotEmpty ? nonRestDays : plan.days;
    final currentIndex = days.indexWhere((d) => d.dayName == lastDayName);
    final nextIndex = currentIndex >= 0 ? (currentIndex + 1) % days.length : 0;
    final nextDay = days[nextIndex];

    ref.read(todayDayOverrideProvider.notifier).state = TodayDayOverride(
      dayName: nextDay.dayName,
      date: DateTime.now(),
    );
    ref.read(completedWorkoutSessionProvider.notifier).state = null;
    ref.invalidate(lastWorkoutProvider);
    context.push('/workout/today');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = todayAsync.asData?.value;
    final session = ref.watch(activeWorkoutSessionProvider);
    final completed = ref.watch(completedWorkoutSessionProvider);
    final lastWorkout = ref.watch(lastWorkoutProvider).asData?.value;

    final inProgress =
        today != null &&
        !today.isRest &&
        session != null &&
        session.isFor(today.dayName, DateTime.now());
    final completedInSession =
        completed != null &&
        completed.isToday() &&
        today != null &&
        completed.dayName == today.dayName;
    final completedFromDB = lastWorkout != null && lastWorkout.isToday;
    final isDoneToday = !inProgress && (completedInSession || completedFromDB);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDoneToday
                        ? context.l10n.workoutDoneToday
                        : inProgress
                        ? context.l10n.workoutInProgress
                        : context.l10n.workoutStart,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (inProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.workoutStatusInProgress,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isDoneToday) ...[
              Text(
                completedInSession
                    ? completed.dayName
                    : (lastWorkout?.dayName ?? ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (completedInSession) ...[
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completed.durationFormatted,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                  ] else if (lastWorkout?.duration != null) ...[
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(lastWorkout!.duration!),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    completedInSession
                        ? context.l10n.workoutExerciseCount(completed.completedCount, completed.totalCount)
                        : context.l10n.exercisesCount(lastWorkout?.exercises.length ?? 0),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ] else
              todayAsync.when(
                data: (today) {
                  if (today.isRest)
                    return Text(context.l10n.workoutRestDay);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        today.dayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (today.focusLabel.isNotEmpty)
                        Text(
                          today.focusLabel,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, s) =>
                    Text(context.l10n.errLoadTodayWorkout),
              ),
            const SizedBox(height: 16),
            if (isDoneToday)
              OutlinedButton.icon(
                onPressed: !isActive || today == null
                    ? null
                    : () => _resetAndTrainAgain(context, ref, today),
                icon: const Icon(Icons.replay),
                label: Text(context.l10n.btnTrainAgain),
              )
            else
              ElevatedButton(
                onPressed: !isActive || todayAsync.asData?.value.isRest == true
                    ? null
                    : () => context.push('/workout/today'),
                child: Text(inProgress ? context.l10n.btnContinueWorkout : context.l10n.workoutStart),
              ),
            if (plan.days.length > 1) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: isActive ? () => _chooseDay(context, ref) : null,
                icon: const Icon(Icons.swap_horiz),
                label: Text(context.l10n.btnSwitchWorkout),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewPlanCard extends StatelessWidget {
  const _ViewPlanCard({this.isActive = true});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.viewPlanTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.viewPlanDesc),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isActive
                  ? () => context.push('/workout/current')
                  : null,
              child: Text(context.l10n.viewPlanButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.progressAsync, this.isActive = true});
  final AsyncValue<ProgressInfo> progressAsync;
  final bool isActive;

  Future<void> _showUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    ProgressInfo? current,
  ) async {
    final weightController = TextEditingController(
      text: current?.currentWeight != null ? '${current!.currentWeight}' : '',
    );
    final heightController = TextEditingController(
      text: current?.currentHeight != null ? '${current!.currentHeight}' : '',
    );

    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.updateMeasuresTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.weightLabel,
                hintText: l.weightHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.heightLabel,
                hintText: l.heightHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancelar),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.salvar),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(heightController.text.replaceAll(',', '.'));

    if (weight == null && height == null) return;

    try {
      await ref
          .read(appApiProvider)
          .updateProgress(weight: weight, height: height);
      ref.invalidate(progressProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errSaveMeasures)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = progressAsync.asData?.value;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? () => _showUpdateDialog(context, ref, current) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.progressTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              progressAsync.when(
                data: (progress) {
                  if (progress.currentWeight == null &&
                      progress.currentHeight == null) {
                    return Text(context.l10n.progressAddMeasures);
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProgressStat(
                        label: context.l10n.progressWeight,
                        value: progress.currentWeight != null
                            ? '${progress.currentWeight} kg'
                            : '—',
                      ),
                      _ProgressStat(
                        label: context.l10n.progressHeight,
                        value: progress.currentHeight != null
                            ? '${progress.currentHeight} cm'
                            : '—',
                      ),
                      _ProgressStat(
                        label: context.l10n.progressLast90Days,
                        value: progress.weightLostPercent != null
                            ? '${progress.weightLostPercent! > 0 ? '-' : '+'}${progress.weightLostPercent!.abs()}%'
                            : '—',
                        valueColor:
                            progress.weightLostPercent != null &&
                                progress.weightLostPercent! > 0
                            ? Colors.green
                            : null,
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, stackTrace) =>
                    Text(context.l10n.errLoadProgress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
