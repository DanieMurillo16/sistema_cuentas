import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/frequent_catalog_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_catalogs_repository.dart';
import '../../../support/fake_movements_repository.dart';

/// Un movimiento del mes actual; [day] más alto = más reciente.
Movement _movement(
  int id, {
  MovementType type = MovementType.expense,
  int categoryId = 3,
  int methodId = 2,
  int day = 1,
}) => buildMovement(
  id: id,
  type: type,
  categoryId: categoryId,
  methodId: methodId,
  date: dayOfCurrentMonth(day),
);

Future<ProviderContainer> _container({
  required List<Movement> movements,
  List<Category>? categories,
  List<PaymentMethod>? methods,
}) async {
  final container = makeContainer(
    overrides: [
      movementsRepositoryProvider.overrideWithValue(
        FakeMovementsRepository(onList: (_, _) async => movements),
      ),
      catalogsRepositoryProvider.overrideWithValue(
        FakeCatalogsRepository(
          onCategories: () async => categories ?? _allCategories,
          onMethods: () async => methods ?? _allMethods,
        ),
      ),
    ],
  );
  container.listen(frequentMethodsProvider, (_, _) {});
  for (final type in MovementType.values) {
    container.listen(frequentCategoriesProvider(type), (_, _) {});
  }
  await container.read(movementsProvider.future);
  await container.read(categoriesProvider.future);
  await container.read(paymentMethodsProvider.future);
  return container;
}

final _allCategories = [
  for (var id = 1; id <= 5; id++) buildCategory(id: id, name: 'Gasto $id'),
  buildCategory(id: 9, type: MovementType.income, name: 'Salario'),
  buildCategory(id: 10, type: MovementType.income, name: 'Ventas'),
];

final _allMethods = [
  buildMethod(id: 2, name: 'Nequi'),
  buildMethod(id: 5, name: 'Bancolombia'),
  buildMethod(id: 6, name: 'Efectivo'),
];

List<int> _ids(Iterable<Object> items) => [
  for (final item in items)
    if (item is Category) item.id else (item as PaymentMethod).id,
];

void main() {
  test('categorías: solo las del tipo, más usada primero y máximo 4', () async {
    final container = await _container(
      movements: [
        _movement(1, categoryId: 1),
        _movement(2, categoryId: 2),
        _movement(3, categoryId: 2),
        _movement(4, categoryId: 3),
        _movement(5, categoryId: 4),
        _movement(6, categoryId: 5),
        // Ingresos: no cuentan para los gastos (y al revés).
        _movement(7, type: MovementType.income, categoryId: 9),
        _movement(8, type: MovementType.income, categoryId: 9),
        _movement(9, type: MovementType.income, categoryId: 10),
      ],
    );

    final expense = container.read(
      frequentCategoriesProvider(MovementType.expense),
    );
    expect(_ids(expense), hasLength(4));
    expect(expense.first.id, 2, reason: 'la más usada (2 veces)');
    expect(expense.every((c) => c.type == MovementType.expense), isTrue);
    expect(
      _ids(container.read(frequentCategoriesProvider(MovementType.income))),
      [9, 10],
    );
  });

  test('categorías inactivas no salen como frecuentes', () async {
    final container = await _container(
      movements: [
        _movement(1, categoryId: 1),
        _movement(2, categoryId: 1),
        _movement(3, categoryId: 2),
      ],
      categories: [
        buildCategory(id: 1, name: 'Vieja', active: false),
        buildCategory(id: 2, name: 'Vigente'),
      ],
    );

    expect(
      _ids(container.read(frequentCategoriesProvider(MovementType.expense))),
      [2],
    );
  });

  test('medios: cuentan ingresos y gastos; los inactivos no salen', () async {
    final container = await _container(
      movements: [
        _movement(1, methodId: 5),
        _movement(2, type: MovementType.income, categoryId: 9, methodId: 5),
        _movement(3, methodId: 2),
        _movement(4, methodId: 6),
        _movement(5, methodId: 6),
        _movement(6, methodId: 6),
      ],
      methods: [
        buildMethod(id: 2, name: 'Nequi'),
        buildMethod(id: 5, name: 'Bancolombia'),
        buildMethod(id: 6, name: 'Efectivo', active: false),
      ],
    );

    expect(_ids(container.read(frequentMethodsProvider)), [5, 2]);
  });

  test('sin movimientos no hay frecuentes', () async {
    final container = await _container(movements: const []);

    expect(container.read(frequentMethodsProvider), isEmpty);
    expect(
      container.read(frequentCategoriesProvider(MovementType.expense)),
      isEmpty,
    );
  });

  test(
    'se derivan de movementsProvider: un movimiento nuevo los reordena',
    () async {
      final container = await _container(
        movements: [
          _movement(1, categoryId: 1, methodId: 2),
          _movement(2, categoryId: 1, methodId: 2),
          _movement(3, categoryId: 2, methodId: 5),
        ],
      );
      expect(
        _ids(container.read(frequentCategoriesProvider(MovementType.expense))),
        [1, 2],
      );

      container
          .read(movementsProvider.notifier)
          .upsert(_movement(4, categoryId: 2, methodId: 5, day: 2));
      container
          .read(movementsProvider.notifier)
          .upsert(_movement(5, categoryId: 2, methodId: 5, day: 2));

      expect(
        _ids(container.read(frequentCategoriesProvider(MovementType.expense))),
        [2, 1],
      );
      expect(_ids(container.read(frequentMethodsProvider)), [5, 2]);
    },
  );
}
