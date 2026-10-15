import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_tile.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_delete_dialog.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_tile.dart';

import '../../helpers/recurring_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/delete_recurring_scenario.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/pump_recurring_app.dart';
import '../../support/pump_screen_app.dart';

/// Oscar (ingreso, 2 vencimientos), Netflix (gasto, 1) y un acuerdo ya
/// finalizado (Préstamo viejo).
DeleteRecurringScenario _scenario({
  bool canManage = true,
  Object? failWith,
  String oscarName = 'Arriendo de Oscar',
}) => DeleteRecurringScenario(
  canManage: canManage,
  failWith: failWith,
  dues: [
    buildDue(
      id: 1,
      recurringId: 10,
      description: oscarName,
      contact: 'Oscar',
      dueDate: DateTime(2026, 10, 7),
    ),
    buildDue(
      id: 3,
      recurringId: 10,
      description: oscarName,
      contact: 'Oscar',
      expectedCents: 2000000,
      dueDate: DateTime(2026, 10, 20),
    ),
    buildDue(
      id: 2,
      recurringId: 11,
      type: MovementType.expense,
      description: 'Netflix',
      category: 'Streaming',
      expectedCents: 4500000,
      dueDate: DateTime(2026, 10, 12),
    ),
  ],
  payments: [
    buildRecurring(
      id: 10,
      description: oscarName,
      contact: 'Oscar',
      nextDueDate: DateTime(2026, 11, 7),
    ),
    buildRecurring(
      id: 11,
      type: MovementType.expense,
      description: 'Netflix',
      category: 'Streaming',
      valueCents: 4500000,
      day: 12,
    ),
    buildRecurring(
      id: 12,
      description: 'Préstamo viejo',
      active: false,
      endDate: DateTime(2026, 9, 30),
    ),
  ],
);

Finder _dueRow(int id) => find.byKey(ValueKey('due-$id'));
Finder _agreementRow(int id) => find.byKey(ValueKey('recurring-$id'));
Finder get _dialog => find.byType(RecurringDeleteDialog);
Finder get _confirm =>
    find.descendant(of: _dialog, matching: find.bySubtype<FilledButton>());
Finder get _decline => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(OutlinedButton, 'Cancelar'),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  DeleteRecurringScenario s,
) => pumpRecurringApp(tester, overrides: s.overrides);

Future<void> _goToAgreements(WidgetTester tester) async {
  await tester.tap(find.text('Acuerdos'));
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, Finder row) async {
  await tester.drag(row, const Offset(-500, 0));
  await tester.pumpAndSettle();
}

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(_confirm);
  await showToast(tester);
}

void main() {
  group('«Este mes»', () {
    testWidgets('con permiso, las filas se deslizan', (tester) async {
      await _pump(tester, _scenario());

      expect(find.byType(Dismissible), findsNWidgets(3));
    });

    testWidgets('deslizar abre el diálogo con el nombre del acuerdo', (
      tester,
    ) async {
      await _pump(tester, _scenario());

      await _swipe(tester, _dueRow(1));

      expect(_dialog, findsOneWidget);
      expect(find.text('Eliminar pago recurrente'), findsOneWidget);
      expect(find.textContaining('¿Eliminar «Oscar»?'), findsOneWidget);
      expect(find.textContaining('cobros'), findsOneWidget);
    });

    testWidgets('un gasto habla de pagos', (tester) async {
      await _pump(tester, _scenario());

      await _swipe(tester, _dueRow(2));

      expect(find.textContaining('¿Eliminar «Netflix»?'), findsOneWidget);
      expect(find.textContaining('Dejará de generar pagos'), findsOneWidget);
    });

    testWidgets('confirmar: salen todas las filas de ese acuerdo, los totales '
        'se vuelven a pedir y las demás se quedan', (tester) async {
      final s = _scenario();
      final container = await _pump(tester, s);
      // Inicio (que vive en otra pestaña del menú) tiene abiertos el resumen y
      // los movimientos: deben volver a pedirse.
      keepAlive(container, [monthSummaryProvider, movementsProvider]);
      await container.read(monthSummaryProvider.future);
      await container.read(movementsProvider.future);
      expect(find.byType(DueTile), findsNWidgets(3));
      expect(find.text(r'$ 200.000'), findsOneWidget, reason: 'Por cobrar');
      expect(s.dues.calls, 1);

      await _swipe(tester, _dueRow(1));
      await _confirmDelete(tester);

      expect(find.text('Pago recurrente eliminado'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(_dueRow(1), findsNothing);
      expect(_dueRow(3), findsNothing, reason: 'otro mes del mismo acuerdo');
      expect(_dueRow(2), findsOneWidget);
      expect(find.byType(DueTile), findsNWidgets(1));
      // Los totales los recalcula el servidor: se vuelven a pedir.
      expect(s.dues.calls, 2);
      expect(find.text(r'$ 200.000'), findsNothing);
      expect(find.text(r'$ 0'), findsOneWidget, reason: 'Por cobrar en cero');
      await container.read(monthSummaryProvider.future);
      await container.read(movementsProvider.future);
      expect(s.summary.calls, 2);
      expect(s.movements.listCalls, 2);
      expect(s.recurring.deleted, [10]);
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });

    testWidgets('eliminar el último deja el estado vacío sin fallar', (
      tester,
    ) async {
      final s = _scenario();
      await _pump(tester, s);
      await _swipe(tester, _dueRow(2));
      await _confirmDelete(tester);
      await dismissToasts(tester);
      await _swipe(tester, _dueRow(1));
      await _confirmDelete(tester);
      await dismissToasts(tester);

      expect(find.byType(DueTile), findsNothing);
      expect(find.text('Sin vencimientos este mes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Cancelar» deja la fila en su sitio', (tester) async {
      final s = _scenario();
      await _pump(tester, s);
      final before = tester.getTopLeft(find.text('Oscar').first);

      await _swipe(tester, _dueRow(1));
      await tester.tap(_decline);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_dueRow(1), findsOneWidget);
      expect(tester.getTopLeft(find.text('Oscar').first), before);
      expect(s.recurring.deleteCalls, 0);
      expect(s.dues.calls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error del servidor: la fila y los totales se quedan', (
      tester,
    ) async {
      final s = _scenario(
        failWith: const ApiException(
          'Este pago recurrente ya está finalizado.',
          code: 'YA_FINALIZADO',
          statusCode: 422,
        ),
      );
      await _pump(tester, s);

      await _swipe(tester, _dueRow(1));
      await _confirmDelete(tester);

      expect(
        find.text('Este pago recurrente ya está finalizado.'),
        findsOneWidget,
      );
      expect(_dialog, findsOneWidget);
      expect(_dueRow(1), findsOneWidget);
      expect(find.text(r'$ 200.000'), findsOneWidget);
      expect(s.dues.calls, 1);
      await dismissToasts(tester);
      await tester.tap(_decline);
      await tester.pumpAndSettle();
      expect(_dueRow(1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin permiso no se desliza ni se abre nada', (tester) async {
      await _pump(tester, _scenario(canManage: false));

      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(_dueRow(1), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_dueRow(1), findsOneWidget);
    });
  });

  group('«Acuerdos»', () {
    testWidgets('solo los ACTIVOS se deslizan', (tester) async {
      await _pump(tester, _scenario());
      await _goToAgreements(tester);

      expect(find.byType(RecurringTile), findsNWidgets(2));
      expect(find.byType(Dismissible), findsNWidgets(2));

      await tester.tap(find.text('Finalizados'));
      await tester.pumpAndSettle();

      expect(find.byType(RecurringTile), findsOneWidget);
      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(_agreementRow(12), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
    });

    testWidgets('deslizar → confirmar: sale de «Activos» y aparece en '
        '«Finalizados»', (tester) async {
      final s = _scenario();
      await _pump(tester, s);
      await _goToAgreements(tester);

      await _swipe(tester, _agreementRow(10));
      expect(find.textContaining('¿Eliminar «Oscar»?'), findsOneWidget);
      await _confirmDelete(tester);
      await dismissToasts(tester);

      expect(_agreementRow(10), findsNothing);
      expect(_agreementRow(11), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Finalizados'));
      await tester.pumpAndSettle();
      expect(_agreementRow(10), findsOneWidget);
      expect(_agreementRow(12), findsOneWidget);
      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('«Este mes» ya no tiene sus vencimientos al volver', (
      tester,
    ) async {
      final s = _scenario();
      await _pump(tester, s);
      await _goToAgreements(tester);

      await _swipe(tester, _agreementRow(10));
      await _confirmDelete(tester);
      await dismissToasts(tester);
      await tester.tap(find.text('Este mes'));
      await tester.pumpAndSettle();

      expect(_dueRow(1), findsNothing);
      expect(_dueRow(3), findsNothing);
      expect(_dueRow(2), findsOneWidget);
      expect(s.dues.calls, greaterThan(1));
    });

    testWidgets('«Cancelar» deja el acuerdo', (tester) async {
      final s = _scenario();
      await _pump(tester, s);
      await _goToAgreements(tester);

      await _swipe(tester, _agreementRow(10));
      await tester.tap(_decline);
      await tester.pumpAndSettle();

      expect(_agreementRow(10), findsOneWidget);
      expect(s.recurring.deleteCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error del servidor: el acuerdo se queda', (tester) async {
      final s = _scenario(failWith: const NetworkException('Sin conexión.'));
      await _pump(tester, s);
      await _goToAgreements(tester);

      await _swipe(tester, _agreementRow(10));
      await _confirmDelete(tester);

      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(_agreementRow(10), findsOneWidget);
      await dismissToasts(tester);
    });

    testWidgets('sin permiso no se desliza', (tester) async {
      await _pump(tester, _scenario(canManage: false));
      await _goToAgreements(tester);

      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(_agreementRow(10), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
    });

    testWidgets('tocar el acuerdo sigue abriendo su detalle', (tester) async {
      await _pump(tester, _scenario());
      await _goToAgreements(tester);

      await tester.tap(find.text('Oscar'));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.text('Historial'), findsOneWidget);
    });
  });

  group('sin desbordes con el diálogo abierto (320/390/800/1300 × teclado × '
      'texto 1.5, nombres largos)', () {
    const longName =
        'Servicios públicos domiciliarios y otros conceptos varios del hogar '
        'de la casa de campo familiar';

    Future<void> centerAndSwipe(WidgetTester tester, Finder row) async {
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
      await tester.pumpAndSettle();
      final rect = tester.getRect(row);
      final height = tester.view.physicalSize.height;
      final y = (rect.top.clamp(0, height) + rect.bottom.clamp(0, height)) / 2;
      await tester.dragFrom(Offset(rect.left + 60, y), const Offset(-1500, 0));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
    }

    testWidgets('desde «Este mes»', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const RecurringScreen(),
        overrides: () => _scenario(oscarName: longName).overrides,
        prepare: (tester) => centerAndSwipe(tester, _dueRow(1)),
      );
    });

    testWidgets('desde «Acuerdos»', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const RecurringScreen(),
        overrides: () => _scenario(oscarName: longName).overrides,
        prepare: (tester) async {
          await _goToAgreements(tester);
          await centerAndSwipe(tester, _agreementRow(10));
        },
      );
    });
  });
}
