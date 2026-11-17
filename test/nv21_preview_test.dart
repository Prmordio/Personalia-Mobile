import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/execution_analysis/data/nv21_preview.dart';

/// NV21 cinza (croma neutro) com luminância [luma](x, y).
Uint8List _nv21(int w, int h, int Function(int x, int y) luma) {
  final bytes = Uint8List(w * h * 3 ~/ 2)..fillRange(w * h, w * h * 3 ~/ 2, 128);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      bytes[y * w + x] = luma(x, y);
    }
  }
  return bytes;
}

int _r(RgbaFrame f, int x, int y) => f.pixels[(y * f.width + x) * 4];

void main() {
  // Buffer 4x2 do sensor; só o canto superior esquerdo é claro.
  final buffer = _nv21(4, 2, (x, y) => x == 0 && y == 0 ? 200 : 10);

  test('should_keep_the_frame_without_rotation', () {
    final f = nv21ToUprightRgba(buffer, 4, 2, 0, step: 1)!;
    expect((f.width, f.height), (4, 2));
    expect(_r(f, 0, 0), 200);
  });

  test('should_rotate_clockwise_like_ml_kit', () {
    // 90° horário: o canto superior esquerdo do sensor vai para o superior direito.
    final f90 = nv21ToUprightRgba(buffer, 4, 2, 90, step: 1)!;
    expect((f90.width, f90.height), (2, 4));
    expect(_r(f90, 1, 0), 200);
    expect(_r(f90, 0, 0), 10);

    final f180 = nv21ToUprightRgba(buffer, 4, 2, 180, step: 1)!;
    expect(_r(f180, 3, 1), 200);

    final f270 = nv21ToUprightRgba(buffer, 4, 2, 270, step: 1)!;
    expect((f270.width, f270.height), (2, 4));
    expect(_r(f270, 0, 3), 200);
  });

  test('should_convert_color_and_downscale', () {
    // Vermelho puro em YUV ≈ (Y 76, U 85, V 255).
    final bytes = Uint8List(4 * 4 * 3 ~/ 2)..fillRange(0, 16, 76);
    for (var i = 16; i < bytes.length; i += 2) {
      bytes[i] = 255; // V
      bytes[i + 1] = 85; // U
    }
    final f = nv21ToUprightRgba(bytes, 4, 4, 90)!;
    expect((f.width, f.height), (2, 2));
    expect(f.pixels.sublist(0, 4), [closeTo(255, 2), closeTo(0, 2), closeTo(0, 2), 255]);
  });

  test('should_reject_truncated_buffers', () {
    expect(nv21ToUprightRgba(Uint8List(10), 4, 4, 90), isNull);
  });

  test('timing_at_720p', () {
    final big = _nv21(1280, 720, (x, y) => (x + y) & 0xff);
    nv21ToUprightRgba(big, 1280, 720, 90);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 10; i++) {
      nv21ToUprightRgba(big, 1280, 720, 90);
    }
    // ignore: avoid_print
    print('nv21 720p -> 360x640: ${sw.elapsedMicroseconds / 10 / 1000} ms/quadro (VM de teste, JIT)');
  });
}
