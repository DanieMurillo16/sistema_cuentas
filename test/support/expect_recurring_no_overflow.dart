import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';

import 'pump_at_sizes.dart';
import 'pump_recurring_app.dart';

/// Igual que `expectNoOverflow`, pero sobre el router mínimo de Pagos
/// recurrentes (`pumpRecurringApp`): así se pueden probar las pantallas con
/// sus rutas reales y llegar, con [prepare], a una sección o a un diálogo
/// abierto con `showDialog` (el diálogo ve el teclado como en la app).
///
/// Con [settle] en `false` (un cargador infinito) avanza un tiempo fijo en
/// vez de esperar el reposo.
///
/// En cada combinación ancho × teclado × escala monta la app desde cero, corre
/// [prepare] (tocar una pestaña, abrir un diálogo…) y falla si Flutter lanzó
/// cualquier excepción (un `RenderFlex overflowed` lo es).
Future<void> expectRecurringNoOverflow(
  WidgetTester tester, {
  required List<Override> Function() overrides,
  String initialLocation = AppRoutes.recurring,
  Future<void> Function(WidgetTester tester)? prepare,
  double height = 700,
  List<double> widths = testWidths,
  List<double> keyboards = testKeyboards,
  List<double> scales = testTextScales,
  bool settle = true,
}) async {
  for (final width in widths) {
    for (final keyboard in keyboards) {
      for (final scale in scales) {
        // Desmonta lo anterior para que cada tamaño parta de cero.
        await tester.pumpWidget(const SizedBox());
        await pumpRecurringApp(
          tester,
          overrides: overrides(),
          initialLocation: initialLocation,
          width: width,
          height: height,
          keyboard: keyboard,
          textScale: scale,
          settle: settle,
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
