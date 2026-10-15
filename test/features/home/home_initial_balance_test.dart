import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/home/widgets/home_empty_message.dart';
import 'package:sistema_cuentas/features/home/widgets/home_type_toggle.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_card.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_dialog.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_appear.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/summary_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/fake_summary_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_router_app.dart';
import '../../support/pump_screen_app.dart' show dismissToasts, showToast;
import '../../support/session_overrides.dart';

MonthSummary get _emptyMonth => buildMonthSummary(
  totals: buildTotals(
    incomeCents: 0,
    expenseCents: 0,
    netFlowCents: 0,
    count: 0,
  ),
  byCategory: const [],
  byMethod: const [],
  dues: const [],
);

/// Un servidor en memoria: lo que se registra aparece en la lista del mes.
class _Server {
  _Server({
    List<Movement> items = const [],
    MonthSummary? previous,
    this.canRegister = true,
  }) : served = List.of(items) {
    movements = FakeMovementsRepository(
      onList: (_, _) async => List.of(served),
      onRegister: (draft) async {
        final movement = buildMovement(
          id: 200 + served.length,
          type: draft.type,
          valueCents: draft.amountPesos * 100,
          description: draft.description,
          categoryId: draft.categoryId,
          methodId: draft.methodId,
          date: draft.date,
        );
        served.add(movement);
        return movement;
      },
    );
    summary = FakeSummaryRepository(
      (_) async => throw StateError('no se usa'),
      onMonth: (month) async {
        final now = DateTime.now();
        final isCurrent = month.year == now.year && month.month == now.month;
        return isCurrent ? _emptyMonth : (previous ?? _emptyMonth);
      },
    );
    catalogs = FakeCatalogsRepository(
      onCategories: () async => [buildCategory(id: 3)],
      onMethods: () async => defaultMethods(),
      onSaveCategory: (draft) async => Category(
        id: 90,
        type: draft.type,
        name: draft.name,
        isCapital: draft.isCapital,
        active: draft.active,
      ),
    );
  }

  final List<Movement> served;
  final bool canRegister;
  late final FakeMovementsRepository movements;
  late final FakeSummaryRepository summary;
  late final FakeCatalogsRepository catalogs;

  List<Override> get overrides => [
    ...sessionOverrides(
      permissions: {
        if (canRegister)
          Permissions.registerMovements
        else
          Permissions.manageCatalogs,
      },
    ).overrides,
    ...dataOverrides(
      movements: movements,
      summary: summary,
      catalogs: catalogs,
    ),
  ];
}

Finder get _card => find.byType(InitialBalanceCard);
Finder get _dialog => find.byType(InitialBalanceDialog);

Future<ProviderContainer> _pump(WidgetTester tester, _Server server) =>
    pumpRouterApp(tester, overrides: server.overrides);

void main() {
  group('la invitación en Inicio', () {
    testWidgets('mes actual vacío y mes anterior vacío: aparece y el «sin '
        'movimientos» sobra', (tester) async {
      await _pump(tester, _Server());

      expect(_card, findsOneWidget);
      expect(find.text('¿Con cuánto cuentas hoy?'), findsOneWidget);
      expect(find.text('Registrar saldo inicial'), findsOneWidget);
      expect(find.byType(HomeEmptyMessage), findsNothing);
      expect(find.text('Sin movimientos este mes'), findsNothing);
    });

    testWidgets('entra con animación (AppAppear) y late (AppPulse)', (
      tester,
    ) async {
      await _pump(tester, _Server());

      expect(
        find.ancestor(of: _card, matching: find.byType(AppAppear)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: _card, matching: find.byType(AppPulse)),
        findsOneWidget,
      );
    });

    testWidgets('sin permiso para registrar movimientos: no', (tester) async {
      await _pump(tester, _Server(canRegister: false));

      expect(_card, findsNothing);
      expect(find.byType(HomeEmptyMessage), findsOneWidget);
    });

    testWidgets('si el mes ya tiene movimientos: no', (tester) async {
      await _pump(
        tester,
        _Server(items: [buildMovement(date: DateTime.now())]),
      );

      expect(_card, findsNothing);
    });

    testWidgets('si el mes anterior tuvo movimientos: no', (tester) async {
      await _pump(tester, _Server(previous: buildMonthSummary()));

      expect(_card, findsNothing);
    });

    testWidgets('viendo otro mes (anterior): no', (tester) async {
      final container = await _pump(tester, _Server());
      expect(_card, findsOneWidget);

      container.read(selectedMonthProvider.notifier).previous();
      await tester.pumpAndSettle();

      expect(_card, findsNothing);
    });

    testWidgets('con el filtro Ingresos o Gastos: no (solo con «Todos»)', (
      tester,
    ) async {
      await _pump(tester, _Server());
      for (final label in ['Gastos', 'Ingresos']) {
        await tester.tap(
          find.descendant(
            of: find.byType(HomeTypeToggle),
            matching: find.ancestor(
              of: find.text(label),
              matching: find.byType(InkWell),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_card, findsNothing, reason: label);
      }

      await tester.tap(
        find.descendant(
          of: find.byType(HomeTypeToggle),
          matching: find.ancestor(
            of: find.text('Todos'),
            matching: find.byType(InkWell),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_card, findsOneWidget);
    });
  });

  group('registrar desde la invitación', () {
    testWidgets('el botón abre el diálogo de saldo inicial', (tester) async {
      await _pump(tester, _Server());

      await tester.tap(find.text('Registrar saldo inicial'));
      await tester.pumpAndSettle();

      expect(_dialog, findsOneWidget);
      expect(find.text('Guardar saldo'), findsOneWidget);
    });

    testWidgets('al guardar, la invitación desaparece y el movimiento sale en '
        'la lista', (tester) async {
      final server = _Server();
      await _pump(tester, server);
      await tester.tap(find.text('Registrar saldo inicial'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('initial-balance-2')),
        '1500000',
      );
      await tester.pump();

      await tester.tap(find.text('Guardar saldo'));
      await showToast(tester);

      expect(find.text('Saldo inicial registrado'), findsOneWidget);
      await dismissToasts(tester);
      expect(_dialog, findsNothing);
      expect(_card, findsNothing, reason: 'ya hay un movimiento este mes');
      expect(find.text('Saldo inicial'), findsWidgets);
      expect(find.text(r'+$ 1.500.000'), findsWidgets);
      expect(server.movements.registerCalls, 1);
      expect(find.byType(HomeEmptyMessage), findsNothing);
    });

    testWidgets('si se cancela el diálogo, la invitación se queda', (
      tester,
    ) async {
      await _pump(tester, _Server());
      await tester.tap(find.text('Registrar saldo inicial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_card, findsOneWidget);
    });
  });

  group('sin desbordes (320/390/800/1300 × teclado × texto 1.5)', () {
    testWidgets('Inicio con la invitación', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const HomeScreen(),
        overrides: () => _Server().overrides,
      );
    });

    testWidgets('con la invitación y el diálogo abierto', (tester) async {
      await expectScreenNoOverflow(
        tester,
        screen: const HomeScreen(),
        overrides: () => _Server().overrides,
        prepare: (tester) async {
          final button = find.text('Registrar saldo inicial');
          if (button.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              button,
              200,
              scrollable: find.byType(Scrollable).first,
            );
          }
          // Se acciona el botón sin depender de dónde cayó en pantalla (con
          // texto grande o teclado puede quedar bajo el encabezado fijo).
          tester
              .widget<FilledButton>(
                find.ancestor(
                  of: find.text('Registrar saldo inicial'),
                  matching: find.bySubtype<FilledButton>(),
                ),
              )
              .onPressed!();
          await tester.pumpAndSettle();
          expect(_dialog, findsOneWidget);
        },
      );
    });
  });
}
