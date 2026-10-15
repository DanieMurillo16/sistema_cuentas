import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/features/home/widgets/home_type_toggle.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/fake_summary_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_at_sizes.dart';

/// 40 movimientos con descripciones de 60+ caracteres, categorías y medios
/// largos e importes de 12 dígitos, repartidos en varios días.
List<Movement> _longMovements() {
  final today = DateTime.now();
  return [
    for (var i = 1; i <= 40; i++)
      buildMovement(
        id: i,
        type: i.isEven ? MovementType.income : MovementType.expense,
        valueCents: i % 3 == 0 ? 99999999999900 : 1234500 * i,
        description: '$longDescription $i',
        category: longCatalogName,
        method: longCatalogName,
        contact: 'Contacto con un nombre bastante largo $i',
        date: DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: i % 6)),
      ),
  ];
}

SummaryTotals get _hugeTotals => buildTotals(
  incomeCents: 99999999999900,
  expenseCents: 99999999999900,
  netFlowCents: -99999999999900,
  count: 40,
);

void main() {
  testWidgets('datos largos (40 movimientos, 12 dígitos, 60+ caracteres)', (
    tester,
  ) async {
    expect(longDescription.length, greaterThan(60));
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: dataOverrides(items: _longMovements(), totals: _hugeTotals),
    );
  });

  testWidgets('desplazar la lista larga hasta el final no lanza excepciones', (
    tester,
  ) async {
    for (final width in [320.0, 390.0, 800.0, 1300.0]) {
      for (final scale in [1.0, 1.5]) {
        await expectNoOverflow(
          tester,
          const HomeScreen(),
          widths: [width],
          keyboards: const [0],
          scales: [scale],
          overrides: dataOverrides(
            items: _longMovements(),
            totals: _hugeTotals,
          ),
        );
        final scroll = find.byType(CustomScrollView);
        for (final dy in [-600.0, -3000.0, -30000.0, 40000.0]) {
          await tester.drag(scroll, Offset(0, dy));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$width px · texto $scale · desplazamiento $dy',
          );
          if (dy == -600.0) {
            // No es una prueba vacía: hay filas pintadas.
            expect(find.byType(MovementTile), findsWidgets);
          }
        }
      }
    }
  });

  testWidgets('cifras tapadas con datos largos', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: [
        ...dataOverrides(items: _longMovements(), totals: _hugeTotals),
        balancesHiddenProvider.overrideWith(_AlwaysHidden.new),
      ],
    );
  });

  testWidgets('mes vacío', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: dataOverrides(totals: _hugeTotals),
    );
  });

  testWidgets('error de carga', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      retry: (_, _) => null,
      overrides: dataOverrides(
        movements: FakeMovementsRepository(
          onList: (_, _) async => throw const NetworkException(
            'No fue posible conectar con el servidor. Revisa tu conexión.',
          ),
        ),
      ),
    );
  });

  testWidgets('cargando (primera carga)', (tester) async {
    final never = Completer<List<Movement>>();
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      settle: false,
      overrides: dataOverrides(
        movements: FakeMovementsRepository(onList: (_, _) => never.future),
      ),
    );
  });

  testWidgets('movimientos listos con el balance cargando', (tester) async {
    final never = Completer<SummaryTotals>();
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      settle: false,
      overrides: dataOverrides(
        items: _longMovements(),
        summary: FakeSummaryRepository((_) => never.future),
      ),
    );
  });

  testWidgets('movimientos listos con el balance en error', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      retry: (_, _) => null,
      overrides: dataOverrides(
        items: _longMovements(),
        summary: FakeSummaryRepository(
          (_) async => throw const ApiException(
            'No se pudo calcular el balance del mes en este momento.',
          ),
        ),
      ),
    );
  });

  testWidgets('conmutador en Ingresos con datos largos', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: [
        ...dataOverrides(items: _longMovements(), totals: _hugeTotals),
        homeTypeFilterProvider.overrideWith(
          () => _FixedFilter(MovementType.income),
        ),
      ],
    );
  });

  testWidgets('conmutador en Gastos con datos largos', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: [
        ...dataOverrides(items: _longMovements(), totals: _hugeTotals),
        homeTypeFilterProvider.overrideWith(
          () => _FixedFilter(MovementType.expense),
        ),
      ],
    );
  });

  testWidgets('conmutador con cifras tapadas y datos largos', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: [
        ...dataOverrides(items: _longMovements(), totals: _hugeTotals),
        homeTypeFilterProvider.overrideWith(
          () => _FixedFilter(MovementType.expense),
        ),
        balancesHiddenProvider.overrideWith(_AlwaysHidden.new),
      ],
    );
  });

  testWidgets('vacío por tipo («Sin ingresos este mes») no desborda', (
    tester,
  ) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: [
        ...dataOverrides(
          items: [buildMovement(id: 1, date: DateTime.now())],
          totals: _hugeTotals,
        ),
        homeTypeFilterProvider.overrideWith(
          () => _FixedFilter(MovementType.income),
        ),
      ],
    );
  });

  testWidgets('vacío por tipo en Gastos no desborda', (tester) async {
    await expectNoOverflow(
      tester,
      const HomeScreen(),
      overrides: [
        ...dataOverrides(
          items: [
            buildMovement(
              id: 1,
              type: MovementType.income,
              date: DateTime.now(),
            ),
          ],
          totals: _hugeTotals,
        ),
        homeTypeFilterProvider.overrideWith(
          () => _FixedFilter(MovementType.expense),
        ),
      ],
    );
  });

  testWidgets('cambiar entre Todos, Ingresos y Gastos tocando no lanza nada', (
    tester,
  ) async {
    for (final width in [320.0, 390.0, 800.0, 1300.0]) {
      for (final scale in [1.0, 1.5]) {
        await expectNoOverflow(
          tester,
          const HomeScreen(),
          widths: [width],
          keyboards: const [0],
          scales: [scale],
          overrides: dataOverrides(
            items: _longMovements(),
            totals: _hugeTotals,
          ),
        );
        for (final label in ['Ingresos', 'Gastos', 'Todos']) {
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
          expect(
            tester.takeException(),
            isNull,
            reason: '$width px · texto $scale · $label',
          );
        }
      }
    }
  });
}

class _FixedFilter extends HomeTypeFilterNotifier {
  _FixedFilter(this.type);

  final MovementType? type;

  @override
  MovementType? build() => type;
}

class _AlwaysHidden extends BalancesHiddenNotifier {
  @override
  bool build() => true;
}
