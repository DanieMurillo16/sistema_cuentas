import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'pump_at_sizes.dart';
import 'pump_screen_app.dart';

/// Igual que `expectNoOverflow`, pero sobre un `GoRouter` mínimo
/// (`pumpScreenApp`): sirve para pantallas con barra «Atrás» (`context.pop`) y
/// permite llegar, con [prepare], a un diálogo abierto con `showDialog` (el
/// diálogo ve el teclado como en la app).
///
/// En cada combinación ancho × teclado × escala monta la app desde cero, corre
/// [prepare] (tocar un botón, abrir un diálogo…) y falla si Flutter lanzó
/// cualquier excepción (un `RenderFlex overflowed` lo es). Con [settle] en
/// `false` (un cargador infinito) avanza un tiempo fijo en vez de esperar.
Future<void> expectScreenNoOverflow(
  WidgetTester tester, {
  required Widget screen,
  required List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? prepare,
  double height = 700,
  List<double> widths = testWidths,
  List<double> keyboards = testKeyboards,
  List<double> scales = testTextScales,
  bool settle = true,
  ThemeData? theme,
}) async {
  for (final width in widths) {
    for (final keyboard in keyboards) {
      for (final scale in scales) {
        // Desmonta lo anterior para que cada tamaño parta de cero.
        await tester.pumpWidget(const SizedBox());
        await pumpScreenApp(
          tester,
          screen: screen,
          overrides: overrides(),
          width: width,
          height: height,
          keyboard: keyboard,
          textScale: scale,
          settle: settle,
          theme: theme,
        );
        if (prepare != null) await prepare(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '$width px · teclado $keyboard · texto $scale',
        );
      }
    }
  }
}
