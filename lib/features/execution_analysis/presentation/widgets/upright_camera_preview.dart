import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _quarterTurns = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeRight: 1,
  DeviceOrientation.portraitDown: 2,
  DeviceOrientation.landscapeLeft: 3,
};

/// Preview sempre em pé numa tela travada em retrato.
///
/// No Android (CameraX) o `buildPreview()` já desconta a rotação que espera que o
/// `CameraPreview` aplique a partir da orientação FÍSICA do aparelho. Só que com a captura
/// travada o `CameraPreview` usa a orientação travada (retrato) — basta inclinar o celular
/// (ou o sensor reportar paisagem com a rotação automática desligada) para o preview girar
/// 90°. Aqui a rotação aplicada é a mesma que o plugin desconta, então elas se anulam.
///
/// Com o preview pausado (gravação no Android) mostra o [liveImage] — quadros do stream da
/// pose, já em pé — no tamanho do próprio quadro, que é o espaço dos landmarks: o [child]
/// (esqueleto) continua alinhado. Sem quadro ainda, fundo preto.
class UprightCameraPreview extends StatelessWidget {
  const UprightCameraPreview(this.controller, {super.key, this.liveImage, this.child});

  final CameraController controller;
  final ValueListenable<ui.Image?>? liveImage;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          final live = liveImage;
          if (value.isPreviewPaused && live != null) {
            return ValueListenableBuilder<ui.Image?>(
              valueListenable: live,
              builder: (context, image, child) => AspectRatio(
                aspectRatio: image == null ? 1 / value.aspectRatio : image.width / image.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image == null)
                      const ColoredBox(color: Color(0xFF000000))
                    else
                      RawImage(image: image, fit: BoxFit.fill),
                    ?child,
                  ],
                ),
              ),
              child: child,
            );
          }
          return AspectRatio(
            aspectRatio: 1 / value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (value.isPreviewPaused)
                  const ColoredBox(color: Color(0xFF000000))
                else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                  RotatedBox(quarterTurns: _quarterTurns[value.deviceOrientation]!, child: controller.buildPreview())
                else
                  controller.buildPreview(),
                ?child,
              ],
            ),
          );
        },
        child: child,
      );
}
