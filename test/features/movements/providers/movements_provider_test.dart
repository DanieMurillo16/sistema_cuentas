import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_movements_repository.dart';

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

ProviderContainer _container(FakeMovementsRepository repository) {
  final container = makeContainer(
    overrides: [movementsRepositoryProvider.overrideWithValue(repository)],
  );
  keepAlive(container, [movementsProvider]);
  return container;
}

void main() {
  test(
    'carga: pide el mes elegido completo y lo ordena (reciente primero)',
    () async {
      final repository = FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(id: 1, date: dayOfCurrentMonth(1)),
          buildMovement(id: 2, date: dayOfCurrentMonth(1)),
          buildMovement(
            id: 3,
            date: dayOfCurrentMonth(1).add(const Duration(days: 1)),
          ),
        ],
      );
      final container = _container(repository);

      final items = await container.read(movementsProvider.future);

      expect(items.map((m) => m.id), [3, 2, 1]);
      final (from, to) = repository.listedRanges.single;
      expect(from, _thisMonth);
      expect(to, DateTime(_thisMonth.year, _thisMonth.month + 1, 0));
    },
  );

  test(
    'cargando: mientras llega la respuesta es AsyncLoading sin datos',
    () async {
      final completer = Completer<List<Movement>>();
      final container = _container(
        FakeMovementsRepository(onList: (_, _) => completer.future),
      );

      expect(container.read(movementsProvider).isLoading, isTrue);
      expect(container.read(movementsProvider).hasValue, isFalse);

      completer.complete([buildMovement()]);
      await container.read(movementsProvider.future);
      expect(container.read(movementsProvider).requireValue, hasLength(1));
    },
  );

  test('vacío: un mes sin movimientos es AsyncData con lista vacía', () async {
    final container = _container(FakeMovementsRepository());
    expect(await container.read(movementsProvider.future), isEmpty);
    expect(container.read(movementsProvider).hasError, isFalse);
  });

  test('error: conserva el mensaje en español del repositorio', () async {
    final container = _container(
      FakeMovementsRepository(
        onList: (_, _) async => throw const NetworkException('Sin conexión.'),
      ),
    );
    await expectLater(
      container.read(movementsProvider.future),
      throwsA(isA<NetworkException>()),
    );
    final state = container.read(movementsProvider);
    expect(state.hasError, isTrue);
    expect(userErrorMessage(state.error), 'Sin conexión.');
  });

  group('upsert', () {
    test('agrega un movimiento del mes mostrado y reordena', () async {
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(id: 1, date: dayOfCurrentMonth(5)),
          ],
        ),
      );
      await container.read(movementsProvider.future);

      container
          .read(movementsProvider.notifier)
          .upsert(buildMovement(id: 2, date: dayOfCurrentMonth(20)));

      expect(container.read(movementsProvider).requireValue.map((m) => m.id), [
        2,
        1,
      ]);
    });

    test('reemplaza si el id ya existe (no duplica)', () async {
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(
              id: 1,
              description: 'Viejo',
              date: dayOfCurrentMonth(5),
            ),
          ],
        ),
      );
      await container.read(movementsProvider.future);

      container
          .read(movementsProvider.notifier)
          .upsert(
            buildMovement(
              id: 1,
              description: 'Nuevo',
              date: dayOfCurrentMonth(5),
            ),
          );

      final items = container.read(movementsProvider).requireValue;
      expect(items, hasLength(1));
      expect(items.single.description, 'Nuevo');
    });

    test(
      'fuera del mes mostrado (anterior o siguiente) no se agrega',
      () async {
        final container = _container(FakeMovementsRepository());
        await container.read(movementsProvider.future);
        final notifier = container.read(movementsProvider.notifier);

        notifier.upsert(
          buildMovement(
            id: 1,
            date: DateTime(_thisMonth.year, _thisMonth.month - 1, 28),
          ),
        );
        notifier.upsert(
          buildMovement(
            id: 2,
            date: DateTime(_thisMonth.year, _thisMonth.month + 1, 1),
          ),
        );
        notifier.upsert(
          buildMovement(
            id: 3,
            date: DateTime(_thisMonth.year - 1, _thisMonth.month, 10),
          ),
        );

        expect(container.read(movementsProvider).requireValue, isEmpty);
      },
    );

    test('antes de cargar no hace nada', () {
      final completer = Completer<List<Movement>>();
      final container = _container(
        FakeMovementsRepository(onList: (_, _) => completer.future),
      );
      container.read(movementsProvider);

      container
          .read(movementsProvider.notifier)
          .upsert(buildMovement(date: dayOfCurrentMonth(1)));

      expect(container.read(movementsProvider).hasValue, isFalse);
      completer.complete(const []);
    });
  });

  group('remove', () {
    test('quita solo ese movimiento', () async {
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(id: 1, date: dayOfCurrentMonth(1)),
            buildMovement(id: 2, date: dayOfCurrentMonth(2)),
          ],
        ),
      );
      await container.read(movementsProvider.future);

      container.read(movementsProvider.notifier).remove(1);

      expect(container.read(movementsProvider).requireValue.map((m) => m.id), [
        2,
      ]);
    });

    test('un id que no existe no cambia nada', () async {
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(id: 1, date: dayOfCurrentMonth(1)),
          ],
        ),
      );
      await container.read(movementsProvider.future);
      container.read(movementsProvider.notifier).remove(99);
      expect(container.read(movementsProvider).requireValue, hasLength(1));
    });
  });

  group('cambio de mes', () {
    test('vuelve a pedir el mes anterior', () async {
      final repository = FakeMovementsRepository(
        onList: (from, _) async => [buildMovement(id: from.month, date: from)],
      );
      final container = _container(repository);
      await container.read(movementsProvider.future);

      container.read(selectedMonthProvider.notifier).previous();
      final items = await container.read(movementsProvider.future);

      expect(repository.listCalls, 2);
      final previous = DateTime(_thisMonth.year, _thisMonth.month - 1);
      expect(repository.listedRanges.last.$1, previous);
      expect(
        repository.listedRanges.last.$2,
        DateTime(previous.year, previous.month + 1, 0),
      );
      expect(items.single.date, previous);
    });

    test('conserva los datos que se ven mientras llega el mes nuevo', () async {
      final second = Completer<List<Movement>>();
      var call = 0;
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) {
            call++;
            return call == 1
                ? Future.value([
                    buildMovement(id: 1, date: dayOfCurrentMonth(1)),
                  ])
                : second.future;
          },
        ),
      );
      await container.read(movementsProvider.future);

      container.read(selectedMonthProvider.notifier).previous();
      final state = container.read(movementsProvider);

      expect(state.isLoading, isTrue);
      expect(state.hasValue, isTrue, reason: 'los datos anteriores siguen ahí');
      expect(state.requireValue.single.id, 1);

      second.complete(const []);
      expect(await container.read(movementsProvider.future), isEmpty);
    });

    test(
      'un upsert en el mes nuevo se compara contra el mes elegido',
      () async {
        final container = _container(FakeMovementsRepository());
        await container.read(movementsProvider.future);
        container.read(selectedMonthProvider.notifier).previous();
        await container.read(movementsProvider.future);

        final previous = DateTime(_thisMonth.year, _thisMonth.month - 1, 10);
        container
            .read(movementsProvider.notifier)
            .upsert(buildMovement(id: 1, date: previous));
        container
            .read(movementsProvider.notifier)
            .upsert(buildMovement(id: 2, date: dayOfCurrentMonth(1)));

        expect(
          container.read(movementsProvider).requireValue.map((m) => m.id),
          [1],
        );
      },
    );
  });

  test(
    'cambiar de cuenta vuelve a pedir los datos (no mezcla cuentas)',
    () async {
      final repository = FakeMovementsRepository();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          movementsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      keepAlive(container, [sessionUserIdProvider]);
      await container.read(sessionProvider.future);
      container.read(sessionProvider.notifier).open(buildSession(id: 1));
      keepAlive(container, [movementsProvider]);
      await container.read(movementsProvider.future);
      expect(repository.listCalls, 1);

      container.read(sessionProvider.notifier).open(buildSession(id: 2));
      await container.read(movementsProvider.future);

      expect(repository.listCalls, 2);
    },
  );
}
