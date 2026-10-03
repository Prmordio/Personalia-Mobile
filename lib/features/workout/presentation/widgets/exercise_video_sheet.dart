import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../home/data/app_api.dart';

Future<void> showExerciseVideoSheet(BuildContext context, {required String exerciseName}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ExerciseVideoSheet(exerciseName: exerciseName),
  );
}

class ExerciseVideoSheet extends ConsumerWidget {
  const ExerciseVideoSheet({super.key, required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(exerciseVideosProvider(exerciseName));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vídeos — $exerciseName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Flexible(
              child: videosAsync.when(
                data: (videos) {
                  if (videos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Nenhum vídeo encontrado.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: video.thumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(video.thumbnail!, width: 80, height: 56, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.play_circle_outline, size: 40),
                        title: Text(video.title ?? 'Vídeo', maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text([video.duration, video.views].whereType<String>().join(' • ')),
                        onTap: video.url == null
                            ? null
                            : () => launchUrl(Uri.parse(video.url!), mode: LaunchMode.externalApplication),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, st) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Não foi possível buscar vídeos.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
