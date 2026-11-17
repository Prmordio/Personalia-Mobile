import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/pose_frame.dart';
import 'nv21_preview.dart';
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

  /// Android: o preview do CameraX fica desligado durante a gravação (ver [startRecording]) e
  /// a tela mostra estes quadros, montados a partir do stream da pose.
  final ValueNotifier<ui.Image?> liveImage = ValueNotifier(null);
  bool _rendering = false;
  final Stopwatch _sinceRender = Stopwatch();
  static const _minRenderIntervalMs = 50;

  /// Só o Android precisa: no iOS o preview segue ligado durante a gravação.
  static bool get drawsOwnPreviewWhileRecording => defaultTargetPlatform == TargetPlatform.android;

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
    // Preview + vídeo + análise juntos fazem o CameraX ligar o StreamSharing em vários
    // Android: o preview chega já rotacionado e o plugin gira de novo (imagem 90° torta,
    // às vezes o vídeo também). Sem o preview ficam só 2 streams — suportados em qualquer
    // aparelho — e a tela mostra a imagem do próprio stream da pose ([liveImage]).
    if (drawsOwnPreviewWhileRecording) await controller.pausePreview();
    await controller.startVideoRecording(onAvailable: _onRecordingImage);
    _clock = Stopwatch()..start();
  }

  Future<RecordedSet> stopRecording() async {
    final file = await _controller!.stopVideoRecording();
    _clock?.stop();
    return RecordedSet(videoPath: file.path, frames: List.of(_frames));
  }

  void _onPreviewImage(CameraImage image) => _process(image, record: false);

  void _onRecordingImage(CameraImage image) {
    if (drawsOwnPreviewWhileRecording) _render(image);
    _process(image, record: true);
  }

  /// Converte o quadro em imagem para a tela. A cópia sai na hora (o buffer da câmera é
  /// reaproveitado); só a decodificação é assíncrona. Quadros chegando enquanto a anterior
  /// decodifica são pulados.
  void _render(CameraImage image) {
    final controller = _controller;
    if (_rendering || controller == null || image.planes.length != 1) return;
    if (_sinceRender.isRunning && _sinceRender.elapsedMilliseconds < _minRenderIntervalMs) return;
    final frame = nv21ToUprightRgba(
      image.planes.first.bytes,
      image.width,
      image.height,
      // Mesma rotação que o ML Kit recebe com a captura travada em retrato.
      controller.description.sensorOrientation,
    );
    if (frame == null) return;
    _rendering = true;
    _sinceRender
      ..reset()
      ..start();
    ui.decodeImageFromPixels(frame.pixels, frame.width, frame.height, ui.PixelFormat.rgba8888, (decoded) {
      _rendering = false;
      if (_controller == null) {
        decoded.dispose();
        return;
      }
      final previous = liveImage.value;
      liveImage.value = decoded;
      previous?.dispose();
    });
  }

  Future<void> _process(CameraImage image, {required bool record}) async {
    final controller = _controller;
    if (_busy || controller == null) return;
    _busy = true;
    final tMs = _clock?.elapsedMilliseconds ?? 0;
    try {
      final detection = await _extractor.process(image, controller.description, DeviceOrientation.portraitUp);
      if (detection == null) return;
      final frame = PoseFrame(tMs, detection.points, aspectRatio: detection.aspectRatio);
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
    liveImage.value?.dispose();
    liveImage.dispose();
  }
}
