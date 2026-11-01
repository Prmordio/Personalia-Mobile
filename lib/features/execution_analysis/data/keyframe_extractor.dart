import 'dart:typed_data';

import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

import '../domain/keyframe_selector.dart';

class Keyframe {
  const Keyframe({required this.jpeg, required this.label});
  final Uint8List jpeg;
  final String label;
}

/// Extrai do vídeo local os quadros escolhidos pelo [selectKeyframes] (nativo:
/// MediaMetadataRetriever OPTION_CLOSEST/AVAssetImageGenerator — quadro exato, não o
/// keyframe de vídeo mais próximo). Só esses JPEGs saem do aparelho.
class KeyframeExtractor {
  const KeyframeExtractor();

  Future<List<Keyframe>> extract(String videoPath, List<KeyframeRequest> requests) async {
    final frames = <Keyframe>[];
    for (final r in requests) {
      try {
        final jpeg = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 720,
          timeMs: r.tMs,
          quality: 75,
        );
        frames.add(Keyframe(jpeg: jpeg, label: r.label));
      } catch (_) {
        // Quadro indisponível (ex.: t além do fim do vídeo): segue com os demais.
      }
    }
    return frames;
  }
}
