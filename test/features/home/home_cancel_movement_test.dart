import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_cancel_dialog.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/cancel_scenario.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/pump_router_app.dart';
import '../../support/pump_screen_app.dart' show dismissToasts, showToast;

/// Hoy: un gasto (Mercado, 25.000) y un ingreso (Salario, 400.000); ayer: otro
/// gasto (Taxi, 7.500).
List<Movement> _items() {
  final today = DateTime.now();
  return [
    buildMovement(id: 3, valueCents: 2500000, date: today),
    buildMovement(
      id: 2,
      type: MovementType.income,
      valueCents: 40000000,
      description: 'Salario',
      category: 'Nómina',
      method: 'Bancolombia',
      date: today,
    ),
    buildMovement(
      id: 1,
      valueCents: 750000,
      description: 'Taxi',
      category: 'Transporte',
      method: 'Efectivo',
      date: today.subtract(const Duration(days: 1)),
    ),
  ];
}

Finder _row(int id) => find.byKey(ValueKey('movement-$id'));
Finder get _dialog => find.byType(MovementCancelDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _decline => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  CancelScenario s, {
  double height = 800,
}) => pumpRouterApp(tester, overrides: s.overrides, height: height);

/// Desliza la fila hacia la izquierda y espera a que salga el diálogo.
Future<void> _swipe(WidgetTester tester, int id) async {
  await tester.drag(_row(id), const Offset(-400, 0));
  await tester.pumpAndSettle();
}

void main() {
  group('con permiso «movimientos.anular»', () {
    testWidgets('deslizar una fila abre el diálogo de eliminar con sus datos', (
      tester,
    ) async {
      await _pump(tester, CancelScenario(items: _items()));

      await _swipe(tester, 3);

      expect(_dialog, findsOneWidget);
      expect(find.text('Eliminar gasto'), findsOneWidget);
      expect(find.text(r'Mercado · -$ 25.000'), findsOneWidget);
      expect(_row(3), findsOneWidget, reason: 'la fila sigue hasta confirmar');
    });

    testWidgets('el ingreso abre «Eliminar ingreso»', (tester) async {
      await _pump(tester, CancelScenario(items: _items()));

      await _swipe(tester, 2);

      expect(find.text('Eliminar ingreso'), findsOneWidget);
    });

    testWidgets('confirmar: la fila desaparece, el neto del día y el balance '
        'se actualizan y el resumen se vuelve a pedir', (tester) async {
      final s = CancelScenario(items: _items());
      await _pump(tester, s);
      expect(find.text(r'+$ 375.000'), findsOneWidget, reason: 'neto de hoy');
      expect(find.text(r'$ 367.500'), findsOneWidget, reason: 'balance');
      expect(s.summary.calls, 1);
      final listCalls = s.movements.listCalls;

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('Movimiento eliminado'), findsOneWidget);
      expect(_dialog, findsNothing);
      await tester.pumpAndSettle();
      expect(_row(3), findsNothing);
      expect(_row(2), findsOneWidget);
      expect(_row(1), findsOneWidget);
      // Neto de hoy: ya sin el gasto de 25.000.
      expect(find.text(r'+$ 400.000'), findsWidgets);
      expect(find.text(r'+$ 375.000'), findsNothing);
      // Balance del mes: lo vuelve a calcular el servidor.
      expect(s.summary.calls, 2);
      expect(find.text(r'$ 367.500'), findsNothing);
      expect(find.text(r'$ 392.500'), findsOneWidget, reason: 'balance nuevo');
      expect(s.movements.listCalls, listCalls, reason: 'sin recargar la lista');
      expect(s.movements.cancelled.single, (
        id: 3,
        reason: 'Eliminado desde la app',
      ));
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });

    testWidgets('el provider compartido ya no tiene el movimiento', (
      tester,
    ) async {
      final s = CancelScenario(items: _items());
      final container = await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(
        container.read(movementsProvider).requireValue.map((m) => m.id),
        containsAll([2, 1]),
      );
      expect(
        container.read(movementsProvider).requireValue.map((m) => m.id),
        isNot(contains(3)),
      );
    });

    testWidgets(
      'eliminar la única fila de un día quita también su encabezado',
      (tester) async {
        final s = CancelScenario(items: _items());
        await _pump(tester, s);
        expect(find.text('Ayer'), findsOneWidget);

        await _swipe(tester, 1);
        await tester.tap(_confirm);
        await showToast(tester);
        await dismissToasts(tester);

        expect(find.text('Ayer'), findsNothing);
        expect(_row(1), findsNothing);
        expect(find.text('Hoy'), findsOneWidget);
      },
    );

    testWidgets('eliminar todo deja el estado vacío y no falla', (
      tester,
    ) async {
      final s = CancelScenario(items: [_items().first]);
      await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(find.byType(MovementTile), findsNothing);
      expect(find.text('Balance disponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Cancelar» deja la fila en su sitio y no llama al servidor', (
      tester,
    ) async {
      final s = CancelScenario(items: _items());
      await _pump(tester, s);
      final before = tester.getTopLeft(find.text('Mercado'));

      await _swipe(tester, 3);
      await tester.tap(_decline);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_row(3), findsOneWidget);
      expect(tester.getTopLeft(find.text('Mercado')), before);
      expect(s.movements.cancelCalls, 0);
      expect(s.summary.calls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('se puede volver a deslizar tras cancelar', (tester) async {
      final s = CancelScenario(items: _items());
      await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      await _swipe(tester, 3);

      expect(_dialog, findsOneWidget);
    });

    testWidgets('error del servidor: la fila se queda, avisa en español y el '
        'balance no cambia', (tester) async {
      final s = CancelScenario(
        items: _items(),
        failWith: const ApiException(
          'El movimiento ya está anulado.',
          code: 'YA_ANULADO',
          statusCode: 422,
        ),
      );
      await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('El movimiento ya está anulado.'), findsOneWidget);
      expect(_dialog, findsOneWidget, reason: 'se puede reintentar');
      expect(_row(3), findsOneWidget);
      expect(s.summary.calls, 1);
      await dismissToasts(tester);

      await tester.tap(_decline);
      await tester.pumpAndSettle();
      expect(_row(3), findsOneWidget);
      expect(find.text(r'+$ 375.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin conexión: mensaje de red y la fila sigue', (tester) async {
      final s = CancelScenario(
        items: _items(),
        failWith: const NetworkException(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);

      expect(
        find.text(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
        findsOneWidget,
      );
      expect(_row(3), findsOneWidget);
      await dismissToasts(tester);
    });

    testWidgets('mientras elimina la fila sigue visible y al terminar sale', (
      tester,
    ) async {
      final s = CancelScenario(items: _items());
      final gate = Completer<void>();
      final original = s.movements.onCancel!;
      s.movements.onCancel = (id, reason) async {
        await gate.future;
        await original(id, reason);
      };
      await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await tester.pump(const Duration(milliseconds: 100));

      expect(_row(3), findsOneWidget);
      expect(_dialog, findsOneWidget);

      gate.complete();
      await showToast(tester);
      await dismissToasts(tester);
      expect(_row(3), findsNothing);
      expect(_dialog, findsNothing);
    });

    testWidgets('un movimiento de un acuerdo recurrente se elimina igual', (
      tester,
    ) async {
      final s = CancelScenario(
        items: [
          buildMovement(
            id: 3,
            date: DateTime.now(),
            description: 'Arriendo',
            fromRecurring: true,
          ),
        ],
      );
      await _pump(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(_row(3), findsNothing);
      expect(s.movements.cancelled.single.id, 3);
    });

    testWidgets('la acción «Eliminar» del lector de pantalla abre el diálogo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, CancelScenario(items: _items()));

      final node = tester.getSemantics(_row(3));
      final ids = node.getSemanticsData().customSemanticsActionIds!;
      expect(CustomSemanticsAction.getAction(ids.single)!.label, 'Eliminar');
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.customAction,
        ids.single,
      );
      await tester.pumpAndSettle();

      expect(_dialog, findsOneWidget);
      handle.dispose();
    });
  });

  group('sin permiso «movimientos.anular»', () {
    testWidgets('las filas no se deslizan ni abren el diálogo', (tester) async {
      await _pump(tester, CancelScenario(items: _items(), canCancel: false));

      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(_row(3), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_row(3), findsOneWidget);
    });

    testWidgets('tampoco ofrecen la acción «Eliminar» al lector de pantalla', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, CancelScenario(items: _items(), canCancel: false));

      final data = tester.getSemantics(_row(3)).getSemanticsData();

      expect(data.customSemanticsActionIds ?? const <int>[], isEmpty);
      handle.dispose();
    });

    testWidgets('el resto de Inicio funciona igual', (tester) async {
      await _pump(tester, CancelScenario(items: _items(), canCancel: false));

      expect(find.byType(MovementTile), findsNWidgets(3));
      expect(find.text('Balance disponible'), findsOneWidget);
    });
  });

  group('sin desbordes con el diálogo abierto desde Inicio', () {
    testWidgets('320/390/800/1300 × teclado × texto 1.5, nombres largos', (
      tester,
    ) async {
      final today = DateTime.now();
      final s = CancelScenario(
        items: [
          buildMovement(
            id: 3,
            date: today,
            description: longDescription,
            category: longCatalogName,
            method: longCatalogName,
            valueCents: 99999999999900,
          ),
          ..._items().skip(1),
        ],
      );
      await expectScreenNoOverflow(
        tester,
        screen: const HomeScreen(),
        overrides: () => CancelScenario(items: s.served).overrides,
        prepare: (tester) async {
          await tester.scrollUntilVisible(
            _row(3),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          // Se centra la fila en la vista (queda lejos del encabezado fijo) y
          // se agarra por su parte alta visible.
          await Scrollable.ensureVisible(
            tester.element(_row(3)),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          final rect = tester.getRect(_row(3));
          final height = tester.view.physicalSize.height;
          final y =
              ((rect.top.clamp(0, height) + rect.bottom.clamp(0, height)) / 2);
          await tester.dragFrom(
            Offset(rect.left + 100, y),
            const Offset(-1500, 0),
          );
          await tester.pumpAndSettle();
          expect(
            _dialog,
            findsOneWidget,
            reason:
                '${tester.view.physicalSize} kb ${tester.view.viewInsets.bottom} fila en $rect',
          );
        },
      );
    });
  });
}
