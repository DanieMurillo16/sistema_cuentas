// Genera los PNG de la marca (icono de la app y del arranque) a partir de
// `BrandMarkPainter`. No es una prueba de la app: se corre a mano con
//   flutter test tool/icon_gen/icon_gen_test.dart
// y deja los archivos en `build/brand/` (ignorado por git). Luego
// `scripts/apply_brand_assets.sh` los copia a iOS, Android y web.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/shared/widgets/brand_mark_painter.dart';

Future<void> _png(
  String name,
  int size, {
  required bool background,
  double markScale = 0.74,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.toDouble();
  if (background) {
    final rect = Rect.fromLTWH(0, 0, side, side);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.balanceStart, AppColors.balanceEnd],
        ).createShader(rect),
    );
  }
  final mark = side * markScale;
  canvas.translate((side - mark) / 2, (side - mark) / 2);
  const BrandMarkPainter(
    color: AppColors.onBrand,
  ).paint(canvas, Size(mark, mark));
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/brand/$name.png')..createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
}

/// El logo de la app (cuadro redondeado con degradado y la marca): lo mismo que
/// dibuja `BrandLogo`, para que el arranque nativo y el de Flutter coincidan.
Future<void> _logo(String name, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.toDouble();
  final rect = Rect.fromLTWH(0, 0, side, side);
  // BrandLogo: radio 12 sobre 72 y marca con 10 % de margen.
  final box = RRect.fromRectAndRadius(rect, Radius.circular(side * 12 / 72));
  canvas.clipRRect(box);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.balanceStart, AppColors.balanceEnd],
      ).createShader(rect),
  );
  final mark = side * 0.8;
  canvas.translate((side - mark) / 2, (side - mark) / 2);
  const BrandMarkPainter(
    color: AppColors.onBrand,
  ).paint(canvas, Size(mark, mark));
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/brand/$name.png')..createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('genera la marca', (tester) async {
    await tester.runAsync(() async {
      // Icono de la app (sin transparencia: lo exige la tienda de Apple).
      await _png('icon_1024', 1024, background: true);
      // Marca sola (fondo transparente) para la pantalla de arranque.
      await _png('mark_360', 360, background: false, markScale: 1);
      await _png('mark_240', 240, background: false, markScale: 1);
      await _png('mark_120', 120, background: false, markScale: 1);
      // Logo de 72 pt para el arranque (1x, 2x y 3x).
      await _logo('logo_72', 72);
      await _logo('logo_144', 144);
      await _logo('logo_216', 216);
    });
  });
}
