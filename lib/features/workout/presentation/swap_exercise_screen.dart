import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/app_api.dart';

class SwapExerciseArgs {
  const SwapExerciseArgs({required this.exercise});
  final WorkoutExercise exercise;
}

final _alternativesProvider = FutureProvider.autoDispose
    .family<List<ExerciseAlternative>, SwapExerciseArgs>((ref, args) {
      final ex = args.exercise;
      return ref
          .watch(appApiProvider)
          .getExerciseAlternatives(
            exerciseName: ex.nome,
            series: ex.series ?? '3',
            reps: ex.repeticoes ?? '12',
            isCardio: ex.modeloDeTreino?.toLowerCase() == 'cardio',
          );
    });

class SwapExerciseScreen extends ConsumerWidget {
  const SwapExerciseScreen({super.key, required this.args});

  final SwapExerciseArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlts = ref.watch(_alternativesProvider(args));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.swapExerciseTitle)),
      body: asyncAlts.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.l10n.swapExerciseSearching(args.exercise.nome),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  context.l10n.swapExerciseError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(_alternativesProvider(args)),
                  child: Text(context.l10n.swapExerciseRetry),
                ),
              ],
            ),
          ),
        ),
        data: (alternatives) {
          if (alternatives.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.swapNoAlternatives,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alternatives.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final alt = alternatives[i];
              return _AlternativeCard(
                alternative: alt,
                originalExercise: args.exercise,
                onTap: () => Navigator.of(context).pop(alt),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.alternative,
    required this.originalExercise,
    required this.onTap,
  });

  final ExerciseAlternative alternative;
  final WorkoutExercise originalExercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alternative.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (alternative.series != null ||
                        alternative.repeticoes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (alternative.series != null)
                            context.l10n.swapAltSeries(alternative.series!),
                          if (alternative.repeticoes != null)
                            alternative.repeticoes!,
                        ].join(' · '),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
