import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/pose_frame.dart';
import 'pose_extractor.dart';

/// Resultado da gravação: o vídeo (fica só no aparelho) e a pose quadro a quadro.
class RecordedSet {
  const RecordedSet({required this.videoPath, required this.frames});
  final String videoPath;
  final List<PoseFrame> frames;
}

/// Câmera + pose: extrai a pose enquanto mostra o preview (enquadramento) e DURANTE a
/// gravação (`startVideoRecording(onAvailable:)`), com timestamps relativos ao início do
/// vídeo — o overlay casa com o player sem decodificar o vídeo depois.
///
/// Processa um quadro por vez: enquanto o ML Kit trabalha, quadros novos são descartados
/// (dá ~10-15 fps de pose em aparelhos médios, suficiente para reps de agachamento).
class ExecutionRecorder {
  ExecutionRecorder(this._extractor);
  final PoseExtractor _extractor;

  CameraController? _controller;
  bool _busy = false;
  Stopwatch? _clock;
  final List<PoseFrame> _frames = [];

  /// Última pose detectada (preview ou gravação) — alimenta o esqueleto ao vivo.
  final ValueNotifier<PoseFrame?> livePose = ValueNotifier(null);

  CameraController? get controller => _controller;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;
  List<PoseFrame> get recordedFrames => List.unmodifiable(_frames);

  Future<void> initialize({CameraLensDirection lens = CameraLensDirection.back}) async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere((c) => c.lensDirection == lens, orElse: () => cameras.first);
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );
    await controller.initialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    _controller = controller;
    await controller.startImageStream(_onPreviewImage);
  }

  Future<void> startRecording() async {
    final controller = _controller!;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    _frames.clear();
    await controller.startVideoRecording(onAvailable: _onRecordingImage);
    _clock = Stopwatch()..start();
  }

  Future<RecordedSet> stopRecording() async {
    final file = await _controller!.stopVideoRecording();
    _clock?.stop();
    return RecordedSet(videoPath: file.path, frames: List.of(_frames));
  }

  void _onPreviewImage(CameraImage image) => _process(image, record: false);

  void _onRecordingImage(CameraImage image) => _process(image, record: true);

  Future<void> _process(CameraImage image, {required bool record}) async {
    final controller = _controller;
    if (_busy || controller == null) return;
    _busy = true;
    final tMs = _clock?.elapsedMilliseconds ?? 0;
    try {
      final points = await _extractor.process(image, controller.description, DeviceOrientation.portraitUp);
      if (points == null) return;
      final frame = PoseFrame(tMs, points);
      livePose.value = frame;
      if (record && isRecording) _frames.add(frame);
    } catch (e) {
      debugPrint('pose extraction failed: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
      await controller.dispose();
    }
    await _extractor.close();
    livePose.dispose();
  }
}
