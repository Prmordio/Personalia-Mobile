import '../../workout/presentation/workout_session_actions.dart';
import '../../workout/state/workout_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../data/app_api.dart';
import '../../auth/presentation/biometric_offer_gate.dart';
import '../../workout/state/active_workout_session.dart';
import '../../workout/state/completed_workout_session.dart';
import '../state/feature_access.dart';
import '../state/today_workout_override.dart';
import 'subscription_checkout.dart';
import 'widgets/subscription_card.dart';
import 'widgets/tip_card.dart';
import 'widgets/no_workout_card.dart';
import 'widgets/start_workout_card.dart';
import 'widgets/view_plan_card.dart';
import 'widgets/progress_card.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(currentWorkoutProvider);
    final tipAsync = ref.watch(todayTipProvider);
    final todayWorkoutAsync = ref.watch(effectiveTodayWorkoutProvider);
    final progressAsync = ref.watch(progressProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    ref.watch(activeWorkoutSessionProvider);
    final cachedSession = ref.read(workoutSessionCacheProvider).active;
    final completedLocal = ref.watch(completedWorkoutSessionProvider);
    final cachedToday = todayWorkoutAsync.asData?.value;
    final Widget? offlineWorkoutCard =
        cachedSession != null && cachedToday != null
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.workoutInProgress),
                  Text(
                    cachedToday.dayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/workout/today'),
                    child: Text(context.l10n.btnContinueWorkout),
                  ),
                  TextButton(
                    onPressed: () => cancelWorkoutSession(context, ref),
                    child: Text(context.l10n.cancelWorkoutLabel),
                  ),
                ],
              ),
            ),
          )
        : completedLocal?.isToday() == true
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(context.l10n.workoutDoneToday),
            ),
          )
        : null;

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
                data: (subscription) => SubscriptionCard(
                  subscription: subscription,
                  onSubscribe: () => openSubscriptionCheckout(context, ref),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              workoutAsync.when(
                data: (workout) {
                  final isActive = ref.watch(featureAccessProvider);
                  return workout == null
                      ? offlineWorkoutCard ?? const NoWorkoutCard()
                      : Column(
                          children: [
                            StartWorkoutCard(
                              todayAsync: todayWorkoutAsync,
                              plan: workout,
                              isActive: isActive,
                            ),
                            const SizedBox(height: 16),
                            ViewPlanCard(isActive: isActive),
                            const SizedBox(height: 16),
                            ProgressCard(
                              progressAsync: progressAsync,
                              isActive: isActive,
                            ),
                            // Dica do dia já aberta, logo abaixo da evolução.
                            ...tipAsync.maybeWhen(
                              data: (tip) => tip.texto == null
                                  ? const <Widget>[]
                                  : [
                                      const SizedBox(height: 16),
                                      TipCard(tip: tip),
                                    ],
                              orElse: () => const <Widget>[],
                            ),
                          ],
                        );
                },
                loading: () =>
                    offlineWorkoutCard ??
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                error: (error, stackTrace) =>
                    offlineWorkoutCard ?? Text(context.l10n.errLoadWorkout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nome da loja que cobra a assinatura (marca, sem tradução).
