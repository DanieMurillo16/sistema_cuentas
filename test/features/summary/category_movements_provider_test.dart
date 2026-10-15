import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/category_movements_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_movements_repository.dart';

void main() {
  test(
    'filtra la lista de Inicio por categoría Y por tipo, sin pedir nada nuevo',
    () async {
      final repo = FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(
            id: 1,
            description: 'Mercado',
            date: DateTime(2026, 10, 3),
          ),
          buildMovement(id: 2, description: 'Pan', date: DateTime(2026, 10, 5)),
          buildMovement(
            id: 3,
            description: 'Taxi',
            categoryId: 4,
            category: 'Transporte',
            date: DateTime(2026, 10, 4),
          ),
          buildMovement(
            id: 4,
            type: MovementType.income,
            description: 'Reembolso',
            date: DateTime(2026, 10, 6),
          ),
        ],
      );
      final container = makeContainer(
        overrides: [movementsRepositoryProvider.overrideWithValue(repo)],
      );
      keepAlive(container, [movementsProvider]);
      await container.read(movementsProvider.future);

      final expenses = container.read(
        categoryMovementsProvider((categoryId: 3, type: MovementType.expense)),
      );
      final incomes = container.read(
        categoryMovementsProvider((categoryId: 3, type: MovementType.income)),
      );

      expect(expenses.map((m) => m.description).toSet(), {'Mercado', 'Pan'});
      expect(incomes.map((m) => m.description), ['Reembolso']);
      expect(
        container.read(
          categoryMovementsProvider((
            categoryId: 99,
            type: MovementType.expense,
          )),
        ),
        isEmpty,
      );
      expect(repo.listCalls, 1);
    },
  );

  test(
    'antes de que cargue la lista (o con error) devuelve vacío, no revienta',
    () {
      final container = makeContainer(
        overrides: [
          movementsRepositoryProvider.overrideWithValue(
            FakeMovementsRepository(
              onList: (_, _) async => throw StateError('x'),
            ),
          ),
        ],
      );
      expect(
        container.read(
          categoryMovementsProvider((
            categoryId: 3,
            type: MovementType.expense,
          )),
        ),
        isEmpty,
      );
    },
  );
}
