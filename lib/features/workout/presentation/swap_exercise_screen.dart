import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/app_api.dart';
import '../../../core/theme/app_theme.dart';

class SwapExerciseArgs {
  const SwapExerciseArgs({required this.exercise});
  final WorkoutExercise exercise;
}

final _alternativesProvider =
    FutureProvider.autoDispose.family<List<ExerciseAlternative>, SwapExerciseArgs>((ref, args) {
  final ex = args.exercise;
  return ref.watch(appApiProvider).getExerciseAlternatives(
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
      appBar: AppBar(title: const Text('Trocar Exercício')),
      body: asyncAlts.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Buscando alternativas para\n${args.exercise.nome}...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
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
                const Text('Não foi possível buscar alternativas.\nTente novamente mais tarde.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(_alternativesProvider(args)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (alternatives) {
          if (alternatives.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma alternativa encontrada para este exercício.',
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (alternative.series != null || alternative.repeticoes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (alternative.series != null) '${alternative.series} séries',
                          if (alternative.repeticoes != null) alternative.repeticoes!,
                        ].join(' · '),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
