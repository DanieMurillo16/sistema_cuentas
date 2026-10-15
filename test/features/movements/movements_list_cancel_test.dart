import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_tile.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_cancel_dialog.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/cancel_scenario.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/pump_router_app.dart';
import '../../support/pump_screen_app.dart';

/// Dos gastos (Mercado 25.000 y Taxi 7.500) y un ingreso (Salario 400.000).
List<Movement> _items() => [
  buildMovement(id: 3, valueCents: 2500000, date: dayOfCurrentMonth(1)),
  buildMovement(
    id: 2,
    type: MovementType.income,
    valueCents: 40000000,
    description: 'Salario',
    category: 'Nómina',
    method: 'Bancolombia',
    date: dayOfCurrentMonth(1),
  ),
  buildMovement(
    id: 1,
    valueCents: 750000,
    description: 'Taxi',
    category: 'Transporte',
    method: 'Efectivo',
    date: dayOfCurrentMonth(1),
  ),
];

Finder _row(int id) => find.byKey(ValueKey('movement-$id'));
Finder get _dialog => find.byType(MovementCancelDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _decline => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);

/// Inicio y, encima, la lista de Gastos (se llega tocando la tarjeta, como en
/// la app): Inicio queda debajo, viva.
Future<ProviderContainer> _openExpenses(
  WidgetTester tester,
  CancelScenario s,
) async {
  final container = await pumpRouterApp(tester, overrides: s.overrides);
  await tester.tap(
    find.byWidgetPredicate(
      (w) => w is BalanceStatTile && w.type == MovementType.expense,
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(MovementsListScreen), findsOneWidget);
  return container;
}

Future<void> _swipe(WidgetTester tester, int id) async {
  await tester.drag(_row(id), const Offset(-400, 0));
  await tester.pumpAndSettle();
}

void main() {
  group('lista de Gastos con permiso', () {
    testWidgets('muestra los gastos y su total antes de eliminar', (
      tester,
    ) async {
      await _openExpenses(tester, CancelScenario(items: _items()));

      expect(find.text('2 movimientos'), findsOneWidget);
      expect(find.text(r'$ 32.500'), findsOneWidget);
      expect(find.byType(Dismissible), findsNWidgets(2));
    });

    testWidgets('deslizar → diálogo → confirmar: la fila sale y el conteo y '
        'el total de la lista se actualizan', (tester) async {
      final s = CancelScenario(items: _items());
      await _openExpenses(tester, s);
      final searches = s.movements.searchCalls;

      await _swipe(tester, 3);
      expect(find.text('Eliminar gasto'), findsOneWidget);
      expect(find.text(r'Mercado · -$ 25.000'), findsOneWidget);
      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('Movimiento eliminado'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(_row(3), findsNothing);
      expect(_row(1), findsOneWidget);
      expect(find.text('1 movimiento'), findsOneWidget);
      expect(find.text(r'$ 7.500'), findsOneWidget);
      expect(find.text(r'$ 32.500'), findsNothing);
      expect(
        s.movements.searchCalls,
        searches,
        reason: 'la lista se actualiza sin volver a pedirla',
      );
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });

    testWidgets('Inicio (debajo) también se entera: ni la fila ni el balance '
        'viejo', (tester) async {
      final s = CancelScenario(items: _items());
      final container = await _openExpenses(tester, s);
      expect(s.summary.calls, 1);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(
        container.read(movementsProvider).requireValue.map((m) => m.id),
        isNot(contains(3)),
      );
      // Al volver, Inicio muestra el balance nuevo (400.000 − 7.500).
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      expect(s.summary.calls, 2, reason: 'el resumen se volvió a pedir');
      expect(find.text(r'$ 392.500'), findsOneWidget);
      expect(find.text(r'$ 367.500'), findsNothing);
      expect(_row(3), findsNothing);
    });

    testWidgets('la lista de Ingresos no se toca al eliminar un gasto', (
      tester,
    ) async {
      final s = CancelScenario(items: _items());
      final container = await _openExpenses(tester, s);
      keepAlive(container, MovementType.income);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(
        container
            .read(movementsListProvider(MovementType.income))
            .requireValue
            .map((m) => m.id),
        [2],
      );
    });

    testWidgets('eliminar el último de la lista deja «Sin resultados»', (
      tester,
    ) async {
      final s = CancelScenario(items: [_items().first]);
      await _openExpenses(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);
      await dismissToasts(tester);

      expect(find.byType(MovementTile), findsNothing);
      expect(find.text('Sin resultados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Cancelar»: la fila se queda donde estaba', (tester) async {
      final s = CancelScenario(items: _items());
      await _openExpenses(tester, s);
      final before = tester.getTopLeft(find.text('Mercado'));

      await _swipe(tester, 3);
      await tester.tap(_decline);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_row(3), findsOneWidget);
      expect(tester.getTopLeft(find.text('Mercado')), before);
      expect(find.text('2 movimientos'), findsOneWidget);
      expect(find.text(r'$ 32.500'), findsOneWidget);
      expect(s.movements.cancelCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error del servidor: la fila y el total quedan igual', (
      tester,
    ) async {
      final s = CancelScenario(
        items: _items(),
        failWith: const ApiException(
          'El movimiento ya está anulado.',
          code: 'YA_ANULADO',
          statusCode: 422,
        ),
      );
      await _openExpenses(tester, s);

      await _swipe(tester, 3);
      await tester.tap(_confirm);
      await showToast(tester);

      expect(find.text('El movimiento ya está anulado.'), findsOneWidget);
      expect(_row(3), findsOneWidget);
      expect(find.text(r'$ 32.500'), findsOneWidget);
      expect(s.summary.calls, 1);
      await dismissToasts(tester);
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      expect(_row(3), findsOneWidget);
    });

    testWidgets('el diálogo habla de la fila deslizada (Taxi, no Mercado)', (
      tester,
    ) async {
      final s = CancelScenario(items: _items());
      await _openExpenses(tester, s);

      await _swipe(tester, 1);

      expect(find.text('Eliminar gasto'), findsOneWidget);
      expect(find.text(r'Taxi · -$ 7.500'), findsOneWidget);
    });
  });

  group('lista de Gastos sin permiso', () {
    testWidgets('no se desliza y no hay diálogo', (tester) async {
      await _openExpenses(
        tester,
        CancelScenario(items: _items(), canCancel: false),
      );

      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(_row(3), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_row(3), findsOneWidget);
    });
  });

  group('sin desbordes con el diálogo abierto desde la lista', () {
    testWidgets('320/390/800/1300 × teclado × texto 1.5, nombres largos', (
      tester,
    ) async {
      List<Movement> items() => [
        buildMovement(
          id: 3,
          date: dayOfCurrentMonth(1),
          description: longDescription,
          category: longCatalogName,
          method: longCatalogName,
          valueCents: 99999999999900,
        ),
        buildMovement(id: 1, date: dayOfCurrentMonth(1)),
      ];
      await expectScreenNoOverflow(
        tester,
        screen: const MovementsListScreen(type: MovementType.expense),
        overrides: () => CancelScenario(items: items()).overrides,
        prepare: (tester) async {
          await Scrollable.ensureVisible(
            tester.element(_row(3)),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          final rect = tester.getRect(_row(3));
          final height = tester.view.physicalSize.height;
          final y =
              (rect.top.clamp(0, height) + rect.bottom.clamp(0, height)) / 2;
          await tester.dragFrom(
            Offset(rect.left + 100, y),
            const Offset(-1500, 0),
          );
          await tester.pumpAndSettle();
          expect(_dialog, findsOneWidget);
        },
      );
    });
  });
}

void keepAlive(ProviderContainer container, MovementType type) {
  container.listen(movementsListProvider(type), (_, _) {});
}
