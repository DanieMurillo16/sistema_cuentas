import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/features/movements/widgets/amount_field.dart';

Future<TextEditingController> _pump(
  WidgetTester tester,
  MovementType type,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 700);
  addTearDown(tester.view.reset);
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: AmountField(controller: controller, type: type, enabled: true),
      ),
    ),
  );
  return controller;
}

Finder get _field => find.byType(TextFormField);

void main() {
  for (final (type, caption, color) in [
    (MovementType.expense, 'Valor del gasto', AppColors.expense),
    (MovementType.income, 'Valor del ingreso', AppColors.income),
  ]) {
    testWidgets(
      '${type.apiValue}: título fijo arriba y «\$ » del color del tipo '
      'pegado al valor',
      (tester) async {
        final controller = await _pump(tester, type);

        final title = find.text(caption);
        expect(title, findsOneWidget);
        expect(
          tester.getBottomLeft(title).dy,
          lessThanOrEqualTo(tester.getTopLeft(_field).dy + 0.5),
          reason: 'el título va arriba del campo',
        );
        final prefix = tester.widget<Text>(find.text(r'$ '));
        expect(prefix.style?.color, color);
        expect(
          find.descendant(of: _field, matching: find.text(r'$ ')),
          findsOneWidget,
          reason: 'el «\$ » es parte del campo (prefix), no un Text aparte',
        );

        // El título no cambia ni se mueve al escribir.
        final before = tester.getTopLeft(title);
        controller.text = '1.234.567';
        await tester.pump();
        expect(find.text(caption), findsOneWidget);
        expect(tester.getTopLeft(title), before);
      },
    );
  }

  testWidgets('no pide el foco por sí solo (sin autofocus)', (tester) async {
    await _pump(tester, MovementType.expense);
    await tester.pump(const Duration(seconds: 1));

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.autofocus, isFalse);
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('el valor queda centrado, vacío y con una cifra larga', (
    tester,
  ) async {
    final controller = await _pump(tester, MovementType.expense);
    const center = 390 / 2;

    expect(tester.getCenter(_field).dx, closeTo(center, 1));
    expect(
      tester.getCenter(find.text('Valor del gasto')).dx,
      closeTo(center, 1),
    );

    controller.text = '9.999.999.999';
    await tester.pump();
    expect(tester.getCenter(_field).dx, closeTo(center, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('semántica: el nombre del campo se lee una sola vez (el título '
      'queda excluido)', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, MovementType.expense);

    expect(find.bySemanticsLabel(RegExp('Valor del gasto')), findsOneWidget);
    handle.dispose();
  });
}
