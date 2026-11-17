import 'dart:typed_data';

/// Quadro RGBA pronto para `decodeImageFromPixels`.
class RgbaFrame {
  const RgbaFrame(this.pixels, this.width, this.height);
  final Uint8List pixels;
  final int width;
  final int height;
}

/// Converte um buffer NV21 (Y + VU intercalado, como o CameraX entrega) em RGBA já em pé,
/// girando [rotationDegrees] no sentido horário — a mesma rotação passada ao ML Kit, então os
/// landmarks normalizados caem nos mesmos pixels. [step] reduz a resolução (2 = metade) para
/// caber no orçamento de um quadro.
RgbaFrame? nv21ToUprightRgba(
  Uint8List nv21,
  int width,
  int height,
  int rotationDegrees, {
  int step = 2,
}) {
  final frameSize = width * height;
  if (nv21.length < frameSize + frameSize ~/ 2 || step < 1) return null;
  final quarter = (rotationDegrees ~/ 90) % 4;
  final swap = quarter.isOdd;
  final outW = (swap ? height : width) ~/ step;
  final outH = (swap ? width : height) ~/ step;
  final out = Uint8List(outW * outH * 4);

  var o = 0;
  for (var oy = 0; oy < outH; oy++) {
    for (var ox = 0; ox < outW; ox++) {
      final ux = ox * step, uy = oy * step;
      // Pixel do buffer (sensor) que vai para (ux, uy) depois da rotação horária.
      final int ix, iy;
      switch (quarter) {
        case 1:
          ix = uy;
          iy = height - 1 - ux;
        case 2:
          ix = width - 1 - ux;
          iy = height - 1 - uy;
        case 3:
          ix = width - 1 - uy;
          iy = ux;
        default:
          ix = ux;
          iy = uy;
      }
      final y = nv21[iy * width + ix];
      final vu = frameSize + (iy >> 1) * width + (ix & ~1);
      final v = nv21[vu] - 128;
      final u = nv21[vu + 1] - 128;
      // BT.601 em ponto fixo (×1024).
      final r = y + ((1436 * v) >> 10);
      final g = y - ((352 * u + 731 * v) >> 10);
      final b = y + ((1815 * u) >> 10);
      out[o++] = r < 0 ? 0 : (r > 255 ? 255 : r);
      out[o++] = g < 0 ? 0 : (g > 255 ? 255 : g);
      out[o++] = b < 0 ? 0 : (b > 255 ? 255 : b);
      out[o++] = 255;
    }
  }
  return RgbaFrame(out, outW, outH);
}
