import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_form.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_type_picker.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/inicio_overrides.dart';
import '../../../support/open_movement_sheet.dart';
import '../../../support/pump_router_app.dart';

Finder get _fab => find.byTooltip('Nuevo movimiento');
Finder get _back => find.byTooltip('Volver');

Finder get _sheetTitle => find.descendant(
  of: find.byType(NewMovementSheet),
  matching: find.text('Nuevo movimiento'),
);

void main() {
  testWidgets('el «+» de Inicio abre la hoja con Gasto e Ingreso', (
    tester,
  ) async {
    await pumpRouterApp(tester, overrides: dataOverrides());
    expect(find.byType(NewMovementSheet), findsNothing);

    await tester.tap(_fab);
    await tester.pumpAndSettle();

    expect(find.byType(NewMovementSheet), findsOneWidget);
    expect(_sheetTitle, findsOneWidget);
    expect(find.byType(MovementTypePicker), findsOneWidget);
    expect(find.byType(MovementForm), findsNothing);
    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Dinero que sale'), findsOneWidget);
    expect(find.text('Ingreso'), findsOneWidget);
    expect(find.text('Dinero que entra'), findsOneWidget);
    expect(_back, findsNothing, reason: 'en el paso 1 no hay a dónde volver');
  });

  for (final (option, title, button) in [
    ('Gasto', 'Nuevo gasto', 'Registrar gasto'),
    ('Ingreso', 'Nuevo ingreso', 'Registrar ingreso'),
  ]) {
    testWidgets(
      'elegir «$option» muestra el formulario correcto en la MISMA hoja',
      (tester) async {
        await pumpRouterApp(tester, overrides: dataOverrides());
        await tester.tap(_fab);
        await tester.pumpAndSettle();

        await tester.tap(find.text(option));
        await tester.pumpAndSettle();

        expect(find.byType(NewMovementSheet), findsOneWidget);
        expect(find.byType(MovementTypePicker), findsNothing);
        expect(find.byType(MovementForm), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        expect(_sheetTitle, findsNothing);
        expect(find.text(button), findsOneWidget);
        expect(_back, findsOneWidget);
      },
    );
  }

  testWidgets('«Volver» regresa al paso 1 y deja elegir el otro tipo', (
    tester,
  ) async {
    await pumpRouterApp(tester, overrides: dataOverrides());
    await tester.tap(_fab);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);

    await tester.tap(_back);
    await tester.pumpAndSettle();

    expect(find.byType(NewMovementSheet), findsOneWidget);
    expect(_sheetTitle, findsOneWidget);
    expect(find.byType(MovementTypePicker), findsOneWidget);
    expect(find.byType(MovementForm), findsNothing);
    expect(_back, findsNothing);

    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo ingreso'), findsOneWidget);
    expect(find.text('Registrar ingreso'), findsOneWidget);
  });

  testWidgets('al volver se descarta lo escrito del formulario anterior', (
    tester,
  ) async {
    await openMovementSheet(tester, overrides: dataOverrides());
    await tester.tap(find.text('Gasto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '1234');
    expect(find.text('1.234'), findsOneWidget);

    await tester.tap(_back);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gasto'));
    await tester.pumpAndSettle();

    expect(find.text('1.234'), findsNothing);
  });

  testWidgets(
    'la hoja mide como mucho 85 % de la pantalla (sheetMaxHeightFactor)',
    (tester) async {
      expect(DesignTokens.sheetMaxHeightFactor, 0.85);
      await openMovementSheet(tester, height: 700, overrides: dataOverrides());
      final picker = tester.getSize(find.byType(NewMovementSheet)).height;
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();
      final form = tester.getSize(find.byType(NewMovementSheet)).height;

      expect(picker, lessThanOrEqualTo(700 * 0.85));
      expect(form, lessThanOrEqualTo(700 * 0.85));
      expect(form, greaterThan(picker), reason: 'el formulario es más alto');
    },
  );

  testWidgets('tocar fuera cierra la hoja y Inicio queda intacto', (
    tester,
  ) async {
    await openMovementSheet(tester, overrides: dataOverrides());
    expect(find.byType(NewMovementSheet), findsOneWidget);

    await tester.tapAt(const Offset(195, 10)); // el velo, sobre la hoja
    await tester.pumpAndSettle();

    expect(find.byType(NewMovementSheet), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('con datos largos el «+» sigue abriendo la hoja', (tester) async {
    await pumpRouterApp(
      tester,
      overrides: dataOverrides(
        items: [buildMovement(description: longDescription)],
      ),
    );
    await tester.tap(_fab);
    await tester.pumpAndSettle();
    expect(find.byType(NewMovementSheet), findsOneWidget);
  });
}
