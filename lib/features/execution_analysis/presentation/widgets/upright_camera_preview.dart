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
/// Com o preview pausado (durante a gravação) mostra fundo preto no lugar do último quadro
/// congelado — o [child] (esqueleto) continua por cima, no mesmo espaço de coordenadas.
class UprightCameraPreview extends StatelessWidget {
  const UprightCameraPreview(this.controller, {super.key, this.child});

  final CameraController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (context, value, child) {
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
