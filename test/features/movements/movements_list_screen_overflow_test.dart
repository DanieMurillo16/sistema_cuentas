import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/expect_screen_no_overflow.dart';
import '../../support/fake_catalogs_repository.dart';
import '../../support/fake_movements_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pick_catalog_card.dart';

/// 40 movimientos del tipo con descripciones de 60+ caracteres, categorías y
/// medios largos, notas y contactos largos e importes de 12 dígitos.
List<Movement> _longMovements(MovementType type) {
  final today = DateTime.now();
  return [
    for (var i = 1; i <= 40; i++)
      buildMovement(
        id: i,
        type: type,
        valueCents: i % 3 == 0 ? 99999999999900 : 1234500 * i,
        description: '$longDescription $i',
        category: longCatalogName,
        method: longCatalogName,
        contact: 'Contacto con un nombre bastante largo $i',
        note: longDescription,
        date: DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: i % 6)),
      ),
  ];
}

/// Catálogos con nombres de 40+ caracteres.
FakeCatalogsRepository _longCatalogs() => FakeCatalogsRepository(
  onCategories: () async => [
    for (final type in MovementType.values)
      for (var i = 0; i < 6; i++)
        buildCategory(
          id: i + (type.isIncome ? 100 : 0),
          type: type,
          name: '$longCatalogName $i',
        ),
  ],
  onMethods: () async => [
    for (var i = 0; i < 6; i++) buildMethod(id: i, name: '$longCatalogName $i'),
  ],
);

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Filtros'));
  await tester.pumpAndSettle();
}

// Con el teclado abierto el panel se desplaza dentro de su media pantalla:
// `pickFirstCatalogOption` lleva la tarjeta a la vista antes de tocarla.
Future<void> _pickFirst(WidgetTester tester, String field) =>
    pickFirstCatalogOption(tester, field);

void main() {
  for (final type in MovementType.values) {
    final name = type.isIncome ? 'ingresos' : 'gastos';

    group('lista de $name', () {
      testWidgets('datos largos con el panel cerrado', (tester) async {
        expect(longDescription.length, greaterThan(60));
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(
            items: _longMovements(type),
            catalogs: _longCatalogs(),
          ),
        );
      });

      testWidgets('datos largos con el panel abierto', (tester) async {
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(
            items: _longMovements(type),
            catalogs: _longCatalogs(),
          ),
          prepare: _openPanel,
        );
      });

      testWidgets(
        'panel abierto con categoría y medio de 40+ caracteres elegidos',
        (tester) async {
          await expectScreenNoOverflow(
            tester,
            screen: MovementsListScreen(type: type),
            overrides: () => dataOverrides(
              items: _longMovements(type),
              catalogs: _longCatalogs(),
            ),
            prepare: (tester) async {
              await _openPanel(tester);
              await _pickFirst(tester, 'Categoría');
              await _pickFirst(tester, 'Medio de pago');
              expect(find.byTooltip('Quitar'), findsNWidgets(2));
            },
          );
        },
      );

      testWidgets('panel abierto y búsqueda larga sin resultados', (
        tester,
      ) async {
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(
            items: _longMovements(type),
            catalogs: _longCatalogs(),
          ),
          prepare: (tester) async {
            await _openPanel(tester);
            await tester.enterText(find.byType(TextField).first, 'x' * 80);
            await tester.pumpAndSettle();
            expect(find.text('Sin resultados'), findsOneWidget);
          },
        );
      });

      testWidgets('cifras tapadas con datos largos', (tester) async {
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => [
            ...dataOverrides(
              items: _longMovements(type),
              catalogs: _longCatalogs(),
            ),
            balancesHiddenProvider.overrideWith(_AlwaysHidden.new),
          ],
        );
      });

      testWidgets('vacío, con el panel cerrado y abierto', (tester) async {
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(catalogs: _longCatalogs()),
        );
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(catalogs: _longCatalogs()),
          prepare: _openPanel,
        );
      });

      testWidgets('error de carga, con el panel abierto', (tester) async {
        await expectScreenNoOverflow(
          tester,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(
            catalogs: _longCatalogs(),
            movements: FakeMovementsRepository(
              onList: (_, _) async => throw const NetworkException(
                'No fue posible conectar con el servidor. Revisa tu conexión.',
              ),
            ),
          ),
          prepare: _openPanel,
        );
      });

      testWidgets('cargando (primera carga)', (tester) async {
        final never = Completer<List<Movement>>();
        await expectScreenNoOverflow(
          tester,
          settle: false,
          screen: MovementsListScreen(type: type),
          overrides: () => dataOverrides(
            catalogs: _longCatalogs(),
            movements: FakeMovementsRepository(onList: (_, _) => never.future),
          ),
        );
      });

      testWidgets('desplazar la lista larga hasta el final no lanza nada', (
        tester,
      ) async {
        for (final width in [320.0, 1300.0]) {
          await expectScreenNoOverflow(
            tester,
            widths: [width],
            keyboards: const [0],
            scales: const [1.5],
            screen: MovementsListScreen(type: type),
            overrides: () => dataOverrides(
              items: _longMovements(type),
              catalogs: _longCatalogs(),
            ),
          );
          for (final dy in [-600.0, -30000.0, 40000.0]) {
            await tester.drag(find.byType(CustomScrollView), Offset(0, dy));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$width · $dy');
          }
        }
      });
    });
  }
}

class _AlwaysHidden extends BalancesHiddenNotifier {
  @override
  bool build() => true;
}
