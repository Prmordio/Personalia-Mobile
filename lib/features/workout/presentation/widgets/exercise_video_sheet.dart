import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../home/data/app_api.dart';

Future<void> showExerciseVideoSheet(BuildContext context, {required String exerciseName}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ExerciseVideoSheet(exerciseName: exerciseName),
  );
}

/// Extrai o ID do vídeo de uma URL do YouTube em qualquer formato.
String? _extractVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) return uri.pathSegments.firstOrNull;
  if (uri.host.contains('youtube.com')) {
    return uri.queryParameters['v'] ??
        (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1
            ? uri.pathSegments.last
            : null);
  }
  return null;
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
                      final videoId = video.url != null ? _extractVideoId(video.url!) : null;
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
                        onTap: videoId == null
                            ? null
                            : () => _openPlayer(context, videoId: videoId, title: video.title),
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

  void _openPlayer(BuildContext context, {required String videoId, String? title}) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _YoutubePlayerPage(videoId: videoId, title: title),
    ));
  }
}

class _YoutubePlayerPage extends StatefulWidget {
  const _YoutubePlayerPage({required this.videoId, this.title});

  final String videoId;
  final String? title;

  @override
  State<_YoutubePlayerPage> createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<_YoutubePlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Vídeo', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: YoutubePlayerScaffold(
        controller: _controller,
        builder: (context, player) => Column(
          children: [
            player,
          ],
        ),
      ),
    );
  }
}
