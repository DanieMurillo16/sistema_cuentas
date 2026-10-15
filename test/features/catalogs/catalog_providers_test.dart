import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_catalogs_repository.dart';

void main() {
  test('categoriesForType: solo las activas del tipo pedido', () async {
    final container = makeContainer(
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(
          FakeCatalogsRepository(
            onCategories: () async => [
              buildCategory(id: 1, name: 'Mercado'),
              buildCategory(id: 2, name: 'Vieja', active: false),
              buildCategory(id: 3, type: MovementType.income, name: 'Salario'),
            ],
          ),
        ),
      ],
    );
    keepAlive(container, [categoriesProvider]);
    await container.read(categoriesProvider.future);

    final expenses = container.read(
      categoriesForTypeProvider(MovementType.expense),
    );
    final incomes = container.read(
      categoriesForTypeProvider(MovementType.income),
    );

    expect(expenses.requireValue.map((c) => c.name), ['Mercado']);
    expect(incomes.requireValue.map((c) => c.name), ['Salario']);
  });

  test('categoriesForType: cargando y error se propagan', () async {
    final container = makeContainer(
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(
          FakeCatalogsRepository(
            onCategories: () async => throw const NetworkException('Sin red.'),
          ),
        ),
      ],
    );
    keepAlive(container, [categoriesProvider]);
    expect(
      container.read(categoriesForTypeProvider(MovementType.expense)).isLoading,
      isTrue,
    );
    await expectLater(
      container.read(categoriesProvider.future),
      throwsA(isA<NetworkException>()),
    );
    expect(
      container.read(categoriesForTypeProvider(MovementType.expense)).hasError,
      isTrue,
    );
  });

  test(
    'upsert de categoría: reemplaza o agrega y la vista derivada lo ve',
    () async {
      final container = makeContainer(
        overrides: [
          catalogsRepositoryProvider.overrideWithValue(
            FakeCatalogsRepository(
              onCategories: () async => [buildCategory(id: 1, name: 'A')],
            ),
          ),
        ],
      );
      keepAlive(container, [
        categoriesProvider,
        categoriesForTypeProvider(MovementType.expense),
      ]);
      await container.read(categoriesProvider.future);
      final notifier = container.read(categoriesProvider.notifier);

      notifier.upsert(buildCategory(id: 1, name: 'A2'));
      notifier.upsert(buildCategory(id: 2, name: 'B'));

      expect(
        container
            .read(categoriesForTypeProvider(MovementType.expense))
            .requireValue
            .map((c) => c.name),
        ['A2', 'B'],
      );
    },
  );

  test('medios de pago: carga, upsert y error', () async {
    final container = makeContainer(
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(
          FakeCatalogsRepository(
            onMethods: () async => [buildMethod(id: 2, name: 'Nequi')],
          ),
        ),
      ],
    );
    keepAlive(container, [paymentMethodsProvider]);
    await container.read(paymentMethodsProvider.future);

    container
        .read(paymentMethodsProvider.notifier)
        .upsert(buildMethod(id: 5, name: 'Bancolombia'));
    container
        .read(paymentMethodsProvider.notifier)
        .upsert(buildMethod(id: 2, name: 'Nequi 2'));

    expect(
      container.read(paymentMethodsProvider).requireValue.map((m) => m.name),
      ['Bancolombia', 'Nequi 2'], // reemplaza, agrega y ordena por nombre
    );

    final failing = makeContainer(
      overrides: [
        catalogsRepositoryProvider.overrideWithValue(
          FakeCatalogsRepository(
            onMethods: () async => throw const NetworkException('x'),
          ),
        ),
      ],
    );
    keepAlive(failing, [paymentMethodsProvider]);
    await expectLater(
      failing.read(paymentMethodsProvider.future),
      throwsA(isA<NetworkException>()),
    );
  });
}
