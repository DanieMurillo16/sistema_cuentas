import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/brand_logo.dart';
import 'package:sistema_cuentas/shared/widgets/brand_mark_painter.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  ),
);

Finder get _mark => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is BrandMarkPainter,
);

void main() {
  group('BrandMarkPainter', () {
    test('se pinta sin excepciones a muy distintos tamaños', () {
      const painter = BrandMarkPainter(color: Color(0xFFFFFFFF));
      for (final size in const [
        Size.zero,
        Size(1, 1),
        Size(16, 16),
        Size(24, 24),
        Size(72, 72),
        Size(512, 512),
        Size(200, 20), // no cuadrado: manda el lado menor
        Size(20, 200),
        Size(1024, 1024),
      ]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        expect(
          () => painter.paint(canvas, size),
          returnsNormally,
          reason: '$size',
        );
        recorder.endRecording().dispose();
      }
    });

    test('se pinta con cualquier color, también transparente', () {
      for (final color in const [
        Color(0x00000000),
        Color(0xFF000000),
        Color(0x80FF0000),
      ]) {
        final recorder = ui.PictureRecorder();
        expect(
          () =>
              BrandMarkPainter(color: color)
                  .paint(Canvas(recorder), const Size(48, 48)),
          returnsNormally,
        );
        recorder.endRecording().dispose();
      }
    });

    test('shouldRepaint solo cuando cambia el color', () {
      const painter = BrandMarkPainter(color: Color(0xFFFFFFFF));

      expect(
        painter.shouldRepaint(const BrandMarkPainter(color: Color(0xFF000000))),
        isTrue,
      );
      expect(
        painter.shouldRepaint(const BrandMarkPainter(color: Color(0xFFFFFFFF))),
        isFalse,
      );
    });

    testWidgets('dibuja el billete (2 óvalos), 2 puntos, el «\$» y su raya', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox.square(
          dimension: 96,
          child: CustomPaint(painter: BrandMarkPainter(color: Colors.white)),
        ),
      );

      expect(
        tester.renderObject(_mark),
        paints
          ..rrect() // relleno del billete
          ..rrect() // contorno del billete
          ..circle()
          ..circle()
          ..path() // la S
          ..line(), // la raya vertical
      );
    });

    testWidgets('no se sale de su caja (se recorta al tamaño que se le da)', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox.square(
          dimension: 40,
          child: CustomPaint(painter: BrandMarkPainter(color: Colors.white)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_mark), const Size(40, 40));
    });
  });

  group('BrandLogo', () {
    testWidgets('ya no contiene el icono viejo (trending_up) ni ningún Icon', (
      tester,
    ) async {
      await _pump(tester, const BrandLogo());

      expect(find.byIcon(Icons.trending_up_rounded), findsNothing);
      expect(find.byType(Icon), findsNothing);
      expect(
        find.descendant(of: find.byType(BrandLogo), matching: _mark),
        findsOneWidget,
      );
    });

    testWidgets('usa el color de texto del tema para el dibujo', (
      tester,
    ) async {
      await _pump(tester, const BrandLogo());

      final painter =
          tester.widget<CustomPaint>(_mark).painter! as BrandMarkPainter;
      expect(painter.color, AppColors.text);
    });

    testWidgets('tamaño por defecto: el de la cabecera', (tester) async {
      await _pump(tester, const BrandLogo());

      final box = tester.getSize(
        find
            .descendant(
              of: find.byType(BrandLogo),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box, const Size.square(DesignTokens.headerLogoSize));
    });

    testWidgets('el dibujo ocupa el tamaño menos el relleno proporcional', (
      tester,
    ) async {
      for (final size in [24.0, 48.0, DesignTokens.logoSize, 120.0]) {
        await _pump(tester, BrandLogo(size: size));

        expect(tester.getSize(find.byType(BrandLogo)), Size.square(size));
        final inner = size - 2 * size * DesignTokens.logoPaddingRatio;
        expect(tester.getSize(_mark), Size.square(inner), reason: '$size');
        expect(inner, greaterThan(0));
      }
    });

    testWidgets('lleva el degradado de la marca y esquinas redondeadas', (
      tester,
    ) async {
      await _pump(tester, const BrandLogo());

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BrandLogo),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors, [AppColors.balanceStart, AppColors.balanceEnd]);
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('se pinta a varios tamaños sin excepciones', (tester) async {
      for (final size in [12.0, 20.0, 44.0, 72.0, 160.0, 400.0]) {
        await _pump(tester, BrandLogo(size: size));
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  });
}
