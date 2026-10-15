import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/movement_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_movements_repository.dart';

void main() {
  final today = DateTime.now();

  ProviderContainer containerWith(FakeMovementsRepository repository) {
    final container = makeContainer(
      overrides: [movementsRepositoryProvider.overrideWithValue(repository)],
    );
    keepAlive(container, [
      movementsProvider,
      homeTypeFilterProvider,
      homeEntriesProvider,
    ]);
    return container;
  }

  test('sin datos cargados no hay líneas', () {
    final container = containerWith(FakeMovementsRepository());
    expect(container.read(homeEntriesProvider), isEmpty);
  });

  test('agrupa por día con el total neto del día', () async {
    final container = containerWith(
      FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(
            id: 1,
            valueCents: 1000,
            date: DateTime(today.year, today.month, today.day),
          ),
          buildMovement(
            id: 2,
            type: MovementType.income,
            valueCents: 5000,
            date: DateTime(today.year, today.month, today.day),
          ),
        ],
      ),
    );
    await container.read(movementsProvider.future);

    final entries = container.read(homeEntriesProvider);

    expect(entries, hasLength(3));
    final header = entries.first as DayHeaderEntry;
    expect(header.label, 'Hoy');
    expect(header.totalCents, 4000);
  });

  test(
    'el filtro por tipo reduce las líneas sin pedir nada a la red',
    () async {
      final repository = FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(
            id: 1,
            description: 'Mercado',
            date: dayOfCurrentMonth(1),
          ),
          buildMovement(
            id: 2,
            type: MovementType.income,
            description: 'Salario',
            date: dayOfCurrentMonth(1),
          ),
          buildMovement(
            id: 3,
            type: MovementType.income,
            description: 'Venta',
            date: dayOfCurrentMonth(2),
          ),
        ],
      );
      final container = containerWith(repository);
      await container.read(movementsProvider.future);
      List<int> ids() => container
          .read(homeEntriesProvider)
          .whereType<MovementRowEntry>()
          .map((e) => e.movement.id)
          .toList();

      expect(container.read(homeTypeFilterProvider), isNull);
      expect(ids(), unorderedEquals([1, 2, 3]));

      container.read(homeTypeFilterProvider.notifier).set(MovementType.income);
      expect(ids(), [3, 2]);

      container.read(homeTypeFilterProvider.notifier).set(MovementType.expense);
      expect(ids(), [1]);

      container.read(homeTypeFilterProvider.notifier).set(null);
      expect(ids(), hasLength(3));
      expect(repository.listCalls, 1);
      expect(repository.searchCalls, 0);
    },
  );

  test('el total del día se calcula solo con las filas filtradas', () async {
    final container = containerWith(
      FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(id: 1, valueCents: 1000, date: dayOfCurrentMonth(1)),
          buildMovement(
            id: 2,
            type: MovementType.income,
            valueCents: 5000,
            date: dayOfCurrentMonth(1),
          ),
        ],
      ),
    );
    await container.read(movementsProvider.future);

    container.read(homeTypeFilterProvider.notifier).set(MovementType.expense);

    final header = container
        .read(homeEntriesProvider)
        .whereType<DayHeaderEntry>()
        .single;
    expect(header.totalCents, -1000);
  });

  test('filtrar un tipo que no hay deja las líneas vacías', () async {
    final container = containerWith(
      FakeMovementsRepository(
        onList: (_, _) async => [buildMovement(id: 1, date: today)],
      ),
    );
    await container.read(movementsProvider.future);

    container.read(homeTypeFilterProvider.notifier).set(MovementType.income);

    expect(container.read(homeEntriesProvider), isEmpty);
  });

  test('el filtro se reinicia al cambiar de cuenta', () async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        movementsRepositoryProvider.overrideWithValue(
          FakeMovementsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    keepAlive(container, [sessionUserIdProvider]);
    await container.read(sessionProvider.future);
    container.read(sessionProvider.notifier).open(buildSession(id: 1));
    keepAlive(container, [homeTypeFilterProvider]);
    container.read(homeTypeFilterProvider.notifier).set(MovementType.expense);
    expect(container.read(homeTypeFilterProvider), MovementType.expense);

    container.read(sessionProvider.notifier).open(buildSession(id: 2));

    expect(container.read(homeTypeFilterProvider), isNull);
  });

  test(
    'el filtro es autoDispose: sin quien lo observe vuelve a «todos»',
    () async {
      final container = makeContainer();
      final sub = container.listen(homeTypeFilterProvider, (_, _) {});
      container.read(homeTypeFilterProvider.notifier).set(MovementType.income);
      expect(container.read(homeTypeFilterProvider), MovementType.income);

      sub.close();
      await container.pump();

      expect(container.read(homeTypeFilterProvider), isNull);
    },
  );

  test(
    'upsert en movementsProvider se refleja en las líneas de Inicio',
    () async {
      final container = containerWith(FakeMovementsRepository());
      await container.read(movementsProvider.future);

      container
          .read(movementsProvider.notifier)
          .upsert(buildMovement(id: 8, date: today));

      expect(
        container
            .read(homeEntriesProvider)
            .whereType<MovementRowEntry>()
            .single
            .movement
            .id,
        8,
      );
    },
  );
}
