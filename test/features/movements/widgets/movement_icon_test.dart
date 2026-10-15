import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_icon.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/inicio_overrides.dart';
import '../../../support/pump_screen_app.dart';
import '../../../support/session_overrides.dart';

const _income = Icons.south_west_rounded;
const _expense = Icons.north_east_rounded;

List<Override> _overrides(FakeCatalogsRepository catalogs) => [
  ...sessionOverrides().overrides,
  catalogsRepositoryProvider.overrideWithValue(catalogs),
];

FakeCatalogsRepository _catalogs(List<Category> items) =>
    FakeCatalogsRepository(onCategories: () async => items);

/// Monta una fila suelta de [MovementIcon] y devuelve el contenedor.
Future<ProviderContainer> _pumpIcons(
  WidgetTester tester,
  List<Widget> icons,
  FakeCatalogsRepository catalogs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: _overrides(catalogs),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Row(children: icons)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Row).first));
}

Finder _iconAt(int index) => find.descendant(
  of: find.byType(MovementIcon).at(index),
  matching: find.byType(Icon),
);

Icon _icon(WidgetTester tester, [int index = 0]) =>
    tester.widget<Icon>(_iconAt(index));

Color? _circleColor(WidgetTester tester, [int index = 0]) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(MovementIcon).at(index),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  group('MovementIcon: sin categoría o sin icono, la flecha de siempre', () {
    testWidgets('sin categoryId: flecha verde (ingreso) y roja (gasto)', (
      tester,
    ) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.income),
        MovementIcon(type: MovementType.expense),
      ], _catalogs([]));

      expect(_icon(tester, 0).icon, _income);
      expect(_icon(tester, 0).color, MovementType.income.color);
      expect(_icon(tester, 1).icon, _expense);
      expect(_icon(tester, 1).color, MovementType.expense.color);
    });

    testWidgets('sin categoryId no pide las categorías al servidor', (
      tester,
    ) async {
      final catalogs = _catalogs([buildCategory(icon: 'casa')]);
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense),
      ], catalogs);

      expect(catalogs.categoriesCalls, 0);
    });

    testWidgets('categoría sin icono ni color: flecha del tipo', (
      tester,
    ) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3)]));

      expect(_icon(tester).icon, _expense);
      expect(_icon(tester).color, MovementType.expense.color);
    });

    testWidgets('un id que no existe en el catálogo: flecha del tipo', (
      tester,
    ) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.income, categoryId: 999),
      ], _catalogs([buildCategory(id: 3, icon: 'casa', color: '#FB923C')]));

      expect(_icon(tester).icon, _income);
      expect(_icon(tester).color, MovementType.income.color);
    });

    testWidgets('icono o color desconocidos/inválidos: respaldo, sin fallar', (
      tester,
    ) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3, icon: 'zzz', color: 'rojo')]));

      expect(_icon(tester).icon, _expense);
      expect(_icon(tester).color, MovementType.expense.color);
      expect(tester.takeException(), isNull);
    });
  });

  group('MovementIcon: con la categoría', () {
    testWidgets('usa el icono y el color de su categoría', (tester) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3, icon: 'gasolina', color: '#FB923C')]));

      expect(_icon(tester).icon, Icons.local_gas_station_rounded);
      expect(_icon(tester).color?.toARGB32(), 0xFFFB923C);
      expect(
        _circleColor(tester),
        const Color(0xFFFB923C).withValues(alpha: DesignTokens.tintSoft),
      );
    });

    testWidgets('solo icono: el color sigue siendo el del tipo', (
      tester,
    ) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3, icon: 'casa')]));

      expect(_icon(tester).icon, Icons.home_rounded);
      expect(_icon(tester).color, MovementType.expense.color);
    });

    testWidgets('solo color: la flecha, con ese color', (tester) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3, color: '#34D399')]));

      expect(_icon(tester).icon, _expense);
      expect(_icon(tester).color?.toARGB32(), 0xFF34D399);
    });

    testWidgets('cada fila toma su propia categoría', (tester) async {
      await _pumpIcons(
        tester,
        const [
          MovementIcon(type: MovementType.expense, categoryId: 3),
          MovementIcon(type: MovementType.expense, categoryId: 4),
          MovementIcon(type: MovementType.expense, categoryId: 5),
        ],
        _catalogs([
          buildCategory(id: 3, icon: 'casa'),
          buildCategory(id: 4, icon: 'cine'),
          buildCategory(id: 5),
        ]),
      );

      expect(_icon(tester, 0).icon, Icons.home_rounded);
      expect(_icon(tester, 1).icon, Icons.movie_rounded);
      expect(_icon(tester, 2).icon, _expense);
    });

    testWidgets('mide lo de un avatar (círculo de 44)', (tester) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3, icon: 'casa')]));

      expect(
        tester.getSize(find.byType(MovementIcon)),
        const Size.square(DesignTokens.avatarSize),
      );
    });
  });

  group('MovementIcon: estados del catálogo', () {
    testWidgets('mientras cargan las categorías: flecha; al llegar, el icono', (
      tester,
    ) async {
      final pending = Completer<List<Category>>();
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: _overrides(
            FakeCatalogsRepository(onCategories: () => pending.future),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: MovementIcon(type: MovementType.expense, categoryId: 3),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_icon(tester).icon, _expense);

      pending.complete([buildCategory(id: 3, icon: 'casa')]);
      await tester.pumpAndSettle();

      expect(_icon(tester).icon, Icons.home_rounded);
    });

    testWidgets('si las categorías fallan: flecha, sin romper la fila', (
      tester,
    ) async {
      await _pumpIcons(
        tester,
        const [MovementIcon(type: MovementType.income, categoryId: 3)],
        FakeCatalogsRepository(
          onCategories: () async =>
              throw const NetworkException('Sin conexión con el servidor.'),
        ),
      );

      expect(_icon(tester).icon, _income);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lista de categorías vacía: flecha', (tester) async {
      await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([]));

      expect(_icon(tester).icon, _expense);
    });
  });

  group('MovementIcon: datos compartidos (upsert sin recargar)', () {
    testWidgets('tras upsert con un icono nuevo, el icono cambia solo', (
      tester,
    ) async {
      final catalogs = _catalogs([buildCategory(id: 3, icon: 'casa')]);
      final container = await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], catalogs);
      expect(_icon(tester).icon, Icons.home_rounded);

      container
          .read(categoriesProvider.notifier)
          .upsert(buildCategory(id: 3, icon: 'cine', color: '#C084FC'));
      await tester.pump();

      expect(_icon(tester).icon, Icons.movie_rounded);
      expect(_icon(tester).color?.toARGB32(), 0xFFC084FC);
      expect(catalogs.categoriesCalls, 1, reason: 'sin volver a pedir nada');
    });

    testWidgets('upsert que quita el icono vuelve a la flecha', (tester) async {
      final container = await _pumpIcons(tester, const [
        MovementIcon(type: MovementType.expense, categoryId: 3),
      ], _catalogs([buildCategory(id: 3, icon: 'casa', color: '#FB923C')]));

      container.read(categoriesProvider.notifier).upsert(buildCategory(id: 3));
      await tester.pump();

      expect(_icon(tester).icon, _expense);
      expect(_icon(tester).color, MovementType.expense.color);
    });

    testWidgets('upsert de otra categoría no cambia la fila ajena', (
      tester,
    ) async {
      final container = await _pumpIcons(
        tester,
        const [
          MovementIcon(type: MovementType.expense, categoryId: 3),
          MovementIcon(type: MovementType.expense, categoryId: 4),
        ],
        _catalogs([
          buildCategory(id: 3, icon: 'casa'),
          buildCategory(id: 4, icon: 'cine'),
        ]),
      );

      container
          .read(categoriesProvider.notifier)
          .upsert(buildCategory(id: 4, icon: 'taxi'));
      await tester.pump();

      expect(_icon(tester, 0).icon, Icons.home_rounded);
      expect(_icon(tester, 1).icon, Icons.local_taxi_rounded);
    });

    testWidgets(
      'upsert de una categoría nueva: la fila que la esperaba la toma',
      (tester) async {
        final container = await _pumpIcons(tester, const [
          MovementIcon(type: MovementType.expense, categoryId: 77),
        ], _catalogs([buildCategory(id: 3)]));
        expect(_icon(tester).icon, _expense);

        container
            .read(categoriesProvider.notifier)
            .upsert(buildCategory(id: 77, icon: 'mascotas'));
        await tester.pump();

        expect(_icon(tester).icon, Icons.pets_rounded);
      },
    );

    testWidgets(
      'MovementTile (fila del historial) se actualiza tras el upsert',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: _overrides(
              _catalogs([buildCategory(id: 3, icon: 'comida')]),
            ),
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Scaffold(
                body: MovementTile(
                  movement: buildMovement(categoryId: 3),
                  position: RowPosition.only,
                  hidden: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_icon(tester).icon, Icons.restaurant_rounded);

        ProviderScope.containerOf(tester.element(find.byType(MovementTile)))
            .read(categoriesProvider.notifier)
            .upsert(buildCategory(id: 3, icon: 'mercado'));
        await tester.pump();

        expect(_icon(tester).icon, Icons.shopping_cart_rounded);
      },
    );

    testWidgets(
      'en el historial real: editar la categoría cambia el icono de sus filas '
      'y no recarga movimientos ni categorías',
      (tester) async {
        final catalogs = _catalogs([
          buildCategory(id: 3, icon: 'comida'),
          buildCategory(id: 4, name: 'Transporte', icon: 'carro'),
        ]);
        final movements = FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(
              id: 1,
              description: 'Mercado',
              date: dayOfCurrentMonth(1),
            ),
            buildMovement(
              id: 2,
              description: 'Taxi',
              category: 'Transporte',
              categoryId: 4,
              date: dayOfCurrentMonth(1),
            ),
          ],
        );
        final container = await pumpScreenApp(
          tester,
          screen: const MovementsListScreen(type: MovementType.expense),
          overrides: dataOverrides(movements: movements, catalogs: catalogs),
          spanish: true,
        );
        final listCalls = movements.listCalls;

        Icon rowIcon(String description) => tester.widget<Icon>(
          find
              .descendant(
                of: find.widgetWithText(MovementTile, description),
                matching: find.byType(Icon),
              )
              .first,
        );
        expect(rowIcon('Mercado').icon, Icons.restaurant_rounded);
        expect(rowIcon('Taxi').icon, Icons.directions_car_rounded);

        container
            .read(categoriesProvider.notifier)
            .upsert(buildCategory(id: 3, icon: 'gasolina', color: '#FB923C'));
        await tester.pumpAndSettle();

        expect(rowIcon('Mercado').icon, Icons.local_gas_station_rounded);
        expect(rowIcon('Mercado').color?.toARGB32(), 0xFFFB923C);
        expect(rowIcon('Taxi').icon, Icons.directions_car_rounded);
        expect(catalogs.categoriesCalls, 1);
        expect(
          movements.listCalls,
          listCalls,
          reason: 'no recargó movimientos',
        );
      },
    );
  });
}
