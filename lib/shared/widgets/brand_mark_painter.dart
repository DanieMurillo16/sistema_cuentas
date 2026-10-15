import 'dart:math' as math;

import 'package:flutter/material.dart';

/// La marca de la app: un billete con un «$» al centro. Se dibuja con trazos
/// (sin imagen ni fuente), así se ve nítido en cualquier tamaño y el mismo
/// dibujo sirve para la cabecera, la pantalla de carga y el icono.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-8 * math.pi / 180);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: 0.14);

    // El billete.
    final bill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.78, height: s * 0.48),
      Radius.circular(s * 0.07),
    );
    canvas.drawRRect(bill, fill);
    canvas.drawRRect(bill, stroke);

    // Los círculos de las esquinas del billete.
    final dot = Paint()..color = color;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(dx * s * 0.28, 0), s * 0.03, dot);
    }

    // El «$»: una S y una raya vertical.
    final r = s * 0.12;
    final dollar = Path()
      ..moveTo(r * 0.8, -r * 0.7)
      ..cubicTo(r * 0.5, -r * 1.25, -r * 1.0, -r * 1.2, -r * 1.0, -r * 0.45)
      ..cubicTo(-r * 1.0, r * 0.1, r * 1.0, -r * 0.05, r * 1.0, r * 0.5)
      ..cubicTo(r * 1.0, r * 1.25, -r * 0.5, r * 1.25, -r * 0.8, r * 0.7);
    canvas.drawPath(dollar, stroke);
    canvas.drawLine(Offset(0, -r * 1.55), Offset(0, r * 1.55), stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
