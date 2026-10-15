import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

import 'pump_router_app.dart';

/// Abre la hoja del «+» como lo hace la persona: Inicio → FAB «+» → (si se pide
/// un [type]) toca la opción «Ingreso» o «Gasto» para llegar al formulario.
///
/// Devuelve el contenedor para leer providers desde la prueba. Con
/// [settle] en `false` solo avanza un tiempo fijo (útil si algo carga sin fin).
Future<ProviderContainer> openMovementSheet(
  WidgetTester tester, {
  required List<Override> overrides,
  MovementType? type,
  double width = 390,
  double height = 800,
  double keyboard = 0,
  double textScale = 1,
  bool settle = true,
}) async {
  final container = await pumpRouterApp(
    tester,
    overrides: overrides,
    width: width,
    height: height,
    keyboard: keyboard,
    textScale: textScale,
  );
  await tester.tap(find.byTooltip('Nuevo movimiento'));
  await tester.pumpAndSettle();
  if (type == null) return container;
  await tester.tap(find.text(type.isIncome ? 'Ingreso' : 'Gasto'));
  if (settle) {
    await tester.pumpAndSettle();
    // El formulario pide el foco del monto con un `Future.delayed` de 250 ms,
    // que a veces termina después de que las animaciones se asientan.
    await tester.pump(DesignTokens.animationNormal);
  } else {
    // Con una barra de progreso infinita no hay «reposo»: se avanza un tiempo
    // fijo. El formulario pide el foco del monto tras `animationNormal`
    // (250 ms) con un `Future.delayed`: hay que dejarlo cumplirse o la prueba
    // termina con «Timer is still pending».
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(DesignTokens.animationNormal);
  }
  return container;
}
