import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_form.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_type_picker.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_header.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';

import '../../../support/inicio_overrides.dart';
import '../../../support/pump_router_app.dart';

Finder get _back => find.byTooltip('Volver');
Finder get _body => find.descendant(
  of: find.byType(NewMovementSheet),
  matching: find.byType(AnimatedSize),
);

double _bodyHeight(WidgetTester tester) => tester.getSize(_body).height;
double _headerHeight(WidgetTester tester) =>
    tester.getSize(find.byType(NewMovementHeader)).height;

Future<void> _openExpenseForm(WidgetTester tester) async {
  await pumpRouterApp(tester, overrides: dataOverrides());
  await tester.tap(find.byTooltip('Nuevo movimiento'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Gasto'));
  await tester.pumpAndSettle();
}

void main() {
  group('volver del formulario a Ingreso/Gasto: un solo movimiento suave', () {
    testWidgets('el título se funde: durante el cambio conviven los dos', (
      tester,
    ) async {
      await _openExpenseForm(tester);
      expect(find.text('Nuevo movimiento'), findsNothing);

      await tester.tap(_back);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Nuevo gasto'), findsOneWidget, reason: 'aún se va');
      expect(find.text('Nuevo movimiento'), findsOneWidget, reason: 'ya viene');

      await tester.pumpAndSettle();
      expect(find.text('Nuevo gasto'), findsNothing);
      expect(find.text('Nuevo movimiento'), findsOneWidget);
    });

    testWidgets('la hoja ya se achica mientras se funde (no espera al final)', (
      tester,
    ) async {
      await _openExpenseForm(tester);
      final formHeight = _bodyHeight(tester);

      await tester.tap(_back);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        _bodyHeight(tester),
        lessThan(formHeight),
        reason: 'el alto cambia a la vez que el contenido, no después',
      );
      await tester.pumpAndSettle();
    });

    testWidgets('el alto nunca sube ni se queda quieto para saltar después', (
      tester,
    ) async {
      await _openExpenseForm(tester);
      final heights = <double>[_bodyHeight(tester)];

      await tester.tap(_back);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        heights.add(_bodyHeight(tester));
      }

      for (var i = 1; i < heights.length; i++) {
        expect(
          heights[i],
          lessThanOrEqualTo(heights[i - 1] + 0.01),
          reason: '$i',
        );
      }
      // Sin la mesa larga del «dos tiempos»: no hay un tramo plano de más de
      // 3 cuadros (60 ms) antes de empezar a achicarse.
      final flat = heights.takeWhile((h) => h == heights.first).length;
      expect(flat, lessThanOrEqualTo(3), reason: '$heights');
    });

    testWidgets(
      'lo que sale se funde antes de que entre lo nuevo (sin fantasma)',
      (tester) async {
        await pumpRouterApp(tester, overrides: dataOverrides());
        await tester.tap(find.byTooltip('Nuevo movimiento'));
        await tester.pumpAndSettle();

        double opacityOf(Finder inner) => tester
            .widget<FadeTransition>(
              find
                  .ancestor(of: inner, matching: find.byType(FadeTransition))
                  .first,
            )
            .opacity
            .value;

        await tester.tap(find.text('Ingreso'));
        await tester.pump();
        var overlapFrames = 0;
        var sawBothInTree = false;
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 10));
          final picker = find.byType(MovementTypePicker);
          final form = find.byType(MovementForm);
          if (picker.evaluate().isEmpty || form.evaluate().isEmpty) continue;
          sawBothInTree = true;
          if (opacityOf(picker) > 0.01 && opacityOf(form) > 0.01) {
            overlapFrames++;
          }
        }

        expect(sawBothInTree, isTrue, reason: 'hubo transición');
        expect(overlapFrames, 0, reason: 'nunca se ven los dos a la vez');
        await tester.pumpAndSettle();
      },
    );

    testWidgets('el encabezado mide lo mismo en los dos pasos', (tester) async {
      await pumpRouterApp(tester, overrides: dataOverrides());
      await tester.tap(find.byTooltip('Nuevo movimiento'));
      await tester.pumpAndSettle();
      final pickerStep = _headerHeight(tester);

      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      expect(_headerHeight(tester), pickerStep);
    });

    testWidgets('ir a un formulario también es suave: título y alto', (
      tester,
    ) async {
      await pumpRouterApp(tester, overrides: dataOverrides());
      await tester.tap(find.byTooltip('Nuevo movimiento'));
      await tester.pumpAndSettle();
      final pickerHeight = _bodyHeight(tester);

      await tester.tap(find.text('Ingreso'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Nuevo movimiento'), findsOneWidget);
      expect(find.text('Nuevo ingreso'), findsOneWidget);
      expect(_bodyHeight(tester), greaterThan(pickerHeight));
      // El formulario pide el foco con un temporizador: se deja cumplir.
      await tester.pumpAndSettle();
    });
  });
}
