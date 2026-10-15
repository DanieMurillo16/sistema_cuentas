import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/label_amount_row.dart';

import '../../support/expect_layout.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required Widget label,
  required String amount,
  double scale = 1,
  Widget? leading,
  Widget? trailing,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LabelAmountRow(
            leading: leading,
            trailing: trailing,
            label: label,
            amount: Text(
              amount,
              key: const Key('amount'),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    ),
  );
}

/// El ancho que la fila le da a la etiqueta (un `SizedBox` dentro del
/// `Expanded` ocupa todo lo que le den, sin depender de la fuente de prueba).
const _slot = SizedBox(key: Key('label'), height: 10);

Text _text(String text) => Text(text, key: const Key('label'));

Finder get _amountBox => find.ancestor(
  of: find.byKey(const Key('amount')),
  matching: find.byType(FittedBox),
);

void main() {
  testWidgets('la etiqueta usa todo lo que el monto no necesita (no la mitad)', (
    tester,
  ) async {
    await _pump(tester, width: 390, label: _slot, amount: r'$ 50');
    // Fila útil: 358 px. Con un monto corto la etiqueta recibe bastante más de
    // la mitad (con Expanded + Flexible recibía 175 px).
    expect(
      tester.getSize(find.byKey(const Key('label'))).width,
      greaterThan(358 * 0.6),
    );
  });

  testWidgets('el monto queda pegado al borde derecho', (tester) async {
    await _pump(tester, width: 390, label: _slot, amount: r'$ 50');
    final rowRight = tester.getTopRight(find.byType(LabelAmountRow)).dx;
    expect(rowRight - tester.getTopRight(_amountBox).dx, lessThan(1));
    expectSingleLine(tester, find.byKey(const Key('amount')));
  });

  testWidgets('un monto enorme se encoge, no se parte ni desborda', (
    tester,
  ) async {
    await _pump(
      tester,
      width: 320,
      scale: 1.5,
      label: _slot,
      amount: r'$ 999.999.999.999',
    );
    expect(tester.takeException(), isNull);
    expectSingleLine(tester, find.byKey(const Key('amount')));
    // Lo que ocupa en pantalla no pasa de la mitad de la fila (288 px útiles).
    expect(tester.getSize(_amountBox).width, lessThanOrEqualTo(288 * 0.5 + 1));
  });

  testWidgets('una etiqueta larga crece a otra línea y el monto sigue entero', (
    tester,
  ) async {
    await _pump(
      tester,
      width: 320,
      label: _text('Comercializadora internacional de servicios integrales'),
      amount: r'$ 50.000',
    );
    expect(tester.takeException(), isNull);
    expect(textLines(tester, find.byKey(const Key('label'))), greaterThan(1));
    expectSingleLine(tester, find.byKey(const Key('amount')));
  });

  testWidgets('con leading y trailing fijos no desborda', (tester) async {
    await _pump(
      tester,
      width: 320,
      scale: 1.5,
      label: _text('Alimentación'),
      amount: r'$ 1.234.567 · 45 %',
      leading: const SizedBox.square(dimension: 12),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
    expect(tester.takeException(), isNull);
  });
}
