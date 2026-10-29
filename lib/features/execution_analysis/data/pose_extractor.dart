import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../domain/pose_frame.dart';

/// Extrai os landmarks de um quadro da câmera. Interface para trocar o motor de pose
/// (ML Kit hoje; MediaPipe/TFLite depois) sem tocar no domínio.
abstract class PoseExtractor {
  Future<Map<Landmark, PosePoint>?> process(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  );

  Future<void> close();
}

const _landmarkTypes = {
  Landmark.leftShoulder: PoseLandmarkType.leftShoulder,
  Landmark.rightShoulder: PoseLandmarkType.rightShoulder,
  Landmark.leftHip: PoseLandmarkType.leftHip,
  Landmark.rightHip: PoseLandmarkType.rightHip,
  Landmark.leftKnee: PoseLandmarkType.leftKnee,
  Landmark.rightKnee: PoseLandmarkType.rightKnee,
  Landmark.leftAnkle: PoseLandmarkType.leftAnkle,
  Landmark.rightAnkle: PoseLandmarkType.rightAnkle,
  Landmark.leftHeel: PoseLandmarkType.leftHeel,
  Landmark.rightHeel: PoseLandmarkType.rightHeel,
  Landmark.leftFootIndex: PoseLandmarkType.leftFootIndex,
  Landmark.rightFootIndex: PoseLandmarkType.rightFootIndex,
};

const _deviceRotation = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// ML Kit (BlazePose) em modo stream. Os pontos saem normalizados (0..1) no quadro em pé —
/// mesmo espaço do vídeo gravado, para o overlay casar sem conversão.
class MlKitPoseExtractor implements PoseExtractor {
  MlKitPoseExtractor() : _detector = PoseDetector(options: PoseDetectorOptions());
  final PoseDetector _detector;

  @override
  Future<Map<Landmark, PosePoint>?> process(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) async {
    final rotation = _rotation(camera, deviceOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null || image.planes.length != 1) return null;

    final input = InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
    final poses = await _detector.processImage(input);
    if (poses.isEmpty) return null;

    // Mesma convenção do exemplo oficial do ML Kit: no Android os pontos já vêm no espaço
    // rotacionado (largura/altura trocam em 90/270°); no iOS, no espaço do buffer.
    final quarterTurn = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;
    final swap = !Platform.isIOS && quarterTurn;
    final width = (swap ? image.height : image.width).toDouble();
    final height = (swap ? image.width : image.height).toDouble();

    final landmarks = poses.first.landmarks;
    return {
      for (final e in _landmarkTypes.entries)
        if (landmarks[e.value] case final l?) e.key: PosePoint(l.x / width, l.y / height, l.likelihood),
    };
  }

  InputImageRotation? _rotation(CameraDescription camera, DeviceOrientation deviceOrientation) {
    final sensor = camera.sensorOrientation;
    if (Platform.isIOS) return InputImageRotationValue.fromRawValue(sensor);
    final device = _deviceRotation[deviceOrientation];
    if (device == null) return null;
    final compensated = camera.lensDirection == CameraLensDirection.front
        ? (sensor + device) % 360
        : (sensor - device + 360) % 360;
    return InputImageRotationValue.fromRawValue(compensated);
  }

  @override
  Future<void> close() => _detector.close();
}
