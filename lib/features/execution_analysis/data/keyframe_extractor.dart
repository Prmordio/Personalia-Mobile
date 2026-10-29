import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';

import '../domain/keyframe_selector.dart';

class Keyframe {
  const Keyframe({required this.jpeg, required this.label});
  final Uint8List jpeg;
  final String label;
}

/// Extrai do vídeo local os quadros escolhidos pelo [selectKeyframes] (nativo:
/// MediaMetadataRetriever/AVAssetImageGenerator). Só esses JPEGs saem do aparelho.
class KeyframeExtractor {
  const KeyframeExtractor();

  Future<List<Keyframe>> extract(String videoPath, List<KeyframeRequest> requests) async {
    final frames = <Keyframe>[];
    for (final r in requests) {
      final jpeg = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720,
        timeMs: r.tMs,
        quality: 75,
      );
      if (jpeg != null) frames.add(Keyframe(jpeg: jpeg, label: r.label));
    }
    return frames;
  }
}
