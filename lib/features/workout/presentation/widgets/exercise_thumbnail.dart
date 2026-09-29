import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/exercise_image_provider.dart';

/// Miniatura do exercício: foto do aparelho quando existe na base; senão, um ícone.
class ExerciseThumbnail extends ConsumerWidget {
  const ExerciseThumbnail({super.key, required this.exerciseName, this.size = 64, this.isCardio = false});

  final String exerciseName;
  final double size;
  final bool isCardio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(exerciseImageProvider(exerciseName));
    final bytes = image.asData?.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
            : Container(
                color: AppColors.orange.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(
                  isCardio ? Icons.directions_run : Icons.fitness_center,
                  color: AppColors.orange,
                  size: size * 0.45,
                ),
              ),
      ),
    );
  }
}
