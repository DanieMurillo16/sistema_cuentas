import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_recurring_repository.dart';

ProviderContainer _container(FakeRecurringRepository repository) {
  final container = makeContainer(
    overrides: [recurringRepositoryProvider.overrideWithValue(repository)],
  );
  keepAlive(container, [recurringListProvider, visibleRecurringProvider]);
  return container;
}

void main() {
  group('recurringListProvider', () {
    test('trae la lista de la red una sola vez', () async {
      final repository = FakeRecurringRepository(
        onList: () async => [buildRecurring(id: 1), buildRecurring(id: 2)],
      );
      final container = _container(repository);

      final items = await container.read(recurringListProvider.future);

      expect(items.map((p) => p.id), [1, 2]);
      expect(repository.listCalls, 1);
    });

    test('cargando: sin datos hasta que llega la respuesta', () async {
      final completer = Completer<List<RecurringPayment>>();
      final container = _container(
        FakeRecurringRepository(onList: () => completer.future),
      );
      expect(container.read(recurringListProvider).isLoading, isTrue);
      expect(container.read(recurringListProvider).hasValue, isFalse);

      completer.complete(const []);
      await container.read(recurringListProvider.future);
      expect(container.read(recurringListProvider).isLoading, isFalse);
    });

    test('error: AsyncError con el mensaje en español', () async {
      final container = _container(
        FakeRecurringRepository(
          onList: () async => throw const NetworkException('Sin conexión.'),
        ),
      );
      await expectLater(
        container.read(recurringListProvider.future),
        throwsA(isA<NetworkException>()),
      );
      expect(
        userErrorMessage(container.read(recurringListProvider).error),
        'Sin conexión.',
      );
    });

    test('vacío: datos sin elementos, no un error', () async {
      final container = _container(FakeRecurringRepository());
      expect(await container.read(recurringListProvider.future), isEmpty);
      expect(container.read(recurringListProvider).hasError, isFalse);
      expect(container.read(visibleRecurringProvider).requireValue, isEmpty);
    });

    test(
      'invalidate vuelve a pedir y conserva la lista mientras llega',
      () async {
        final second = Completer<List<RecurringPayment>>();
        var call = 0;
        final repository = FakeRecurringRepository(
          onList: () {
            call++;
            return call == 1
                ? Future.value([buildRecurring(id: 1)])
                : second.future;
          },
        );
        final container = _container(repository);
        await container.read(recurringListProvider.future);

        container.invalidate(recurringListProvider);
        await Future<void>.delayed(Duration.zero);

        final reloading = container.read(recurringListProvider);
        expect(reloading.isLoading, isTrue);
        expect(reloading.requireValue.single.id, 1, reason: 'no se vacía');

        second.complete([buildRecurring(id: 1), buildRecurring(id: 2)]);
        expect((await container.read(recurringListProvider.future)).length, 2);
      },
    );

    test(
      'un refresco que falla deja el error pero no pierde el dato anterior',
      () async {
        var fail = false;
        final repository = FakeRecurringRepository(
          onList: () async {
            if (fail) throw const NetworkException('Sin conexión.');
            return [buildRecurring(id: 1)];
          },
        );
        final container = _container(repository);
        await container.read(recurringListProvider.future);

        fail = true;
        container.invalidate(recurringListProvider);
        await expectLater(
          container.read(recurringListProvider.future),
          throwsA(isA<NetworkException>()),
        );

        final state = container.read(recurringListProvider);
        expect(state.hasError, isTrue);
        // Riverpod 3: el AsyncError conserva el valor anterior.
        expect(state.value?.single.id, 1);
        // La lista derivada tampoco se vacía.
        expect(container.read(visibleRecurringProvider).value?.single.id, 1);
      },
    );
  });

  group('upsert', () {
    test('agrega un acuerdo nuevo y reordena por día de pago', () async {
      final container = _container(
        FakeRecurringRepository(
          onList: () async => [
            buildRecurring(id: 1, description: 'Arriendo', day: 7),
            buildRecurring(id: 2, description: 'Netflix', day: 20),
          ],
        ),
      );
      await container.read(recurringListProvider.future);

      container
          .read(recurringListProvider.notifier)
          .upsert(buildRecurring(id: 3, description: 'Gym', day: 12));

      expect(
        container.read(recurringListProvider).requireValue.map((p) => p.id),
        [1, 3, 2],
      );
    });

    test('reemplaza el que ya existe (mismo id) sin duplicarlo', () async {
      final container = _container(
        FakeRecurringRepository(
          onList: () async => [buildRecurring(id: 1, description: 'Viejo')],
        ),
      );
      await container.read(recurringListProvider.future);

      container
          .read(recurringListProvider.notifier)
          .upsert(buildRecurring(id: 1, description: 'Nuevo'));

      final items = container.read(recurringListProvider).requireValue;
      expect(items, hasLength(1));
      expect(items.single.description, 'Nuevo');
    });

    test('con la lista aún sin cargar no hace nada ni revienta', () async {
      final completer = Completer<List<RecurringPayment>>();
      final container = _container(
        FakeRecurringRepository(onList: () => completer.future),
      );

      container
          .read(recurringListProvider.notifier)
          .upsert(buildRecurring(id: 9));

      expect(container.read(recurringListProvider).isLoading, isTrue);
      completer.complete([buildRecurring(id: 1)]);
      expect(
        (await container.read(recurringListProvider.future)).map((p) => p.id),
        [1],
      );
    });

    test('otra vista derivada ve el acuerdo nuevo sin recargar', () async {
      final repository = FakeRecurringRepository(onList: () async => const []);
      final container = _container(repository);
      await container.read(recurringListProvider.future);
      expect(container.read(visibleRecurringProvider).requireValue, isEmpty);

      container
          .read(recurringListProvider.notifier)
          .upsert(buildRecurring(id: 3));

      expect(
        container.read(visibleRecurringProvider).requireValue.single.id,
        3,
      );
      expect(repository.listCalls, 1);
    });
  });

  group('recurringFilterProvider y visibleRecurringProvider', () {
    final items = [
      buildRecurring(id: 1, description: 'Arriendo', day: 7),
      buildRecurring(id: 2, description: 'Viejo', day: 1, active: false),
    ];

    test('por defecto muestra los activos', () async {
      final container = _container(
        FakeRecurringRepository(onList: () async => items),
      );
      await container.read(recurringListProvider.future);

      expect(container.read(recurringFilterProvider), RecurringFilter.active);
      expect(
        container.read(visibleRecurringProvider).requireValue.map((p) => p.id),
        [1],
      );
    });

    test('Finalizados filtra sin volver a pedir a la red', () async {
      final repository = FakeRecurringRepository(onList: () async => items);
      final container = _container(repository);
      await container.read(recurringListProvider.future);

      container
          .read(recurringFilterProvider.notifier)
          .set(RecurringFilter.finished);

      expect(
        container.read(visibleRecurringProvider).requireValue.map((p) => p.id),
        [2],
      );
      expect(repository.listCalls, 1);
    });

    test(
      'al finalizar el último activo, la lista de activos queda vacía',
      () async {
        final container = _container(
          FakeRecurringRepository(onList: () async => [items.first]),
        );
        await container.read(recurringListProvider.future);

        container
            .read(recurringListProvider.notifier)
            .upsert(buildRecurring(id: 1, active: false));

        expect(container.read(visibleRecurringProvider).requireValue, isEmpty);
      },
    );
  });

  group('recurringDetailProvider', () {
    test('pide el detalle de ese id y lo entrega con su historial', () async {
      final repository = FakeRecurringRepository(
        onDetail: (id) async => buildDetail(
          payment: buildRecurring(id: id),
          history: [buildHistoryItem(id: 1), buildHistoryItem(id: 2)],
        ),
      );
      final container = _container(repository);
      keepAlive(container, [recurringDetailProvider(10)]);

      final detail = await container.read(recurringDetailProvider(10).future);

      expect(detail.payment.id, 10);
      expect(detail.history, hasLength(2));
      expect(repository.detailIds, [10]);
    });

    test('cada id tiene su propio detalle', () async {
      final repository = FakeRecurringRepository(
        onDetail: (id) async => buildDetail(payment: buildRecurring(id: id)),
      );
      final container = _container(repository);
      keepAlive(container, [
        recurringDetailProvider(10),
        recurringDetailProvider(11),
      ]);

      await container.read(recurringDetailProvider(10).future);
      await container.read(recurringDetailProvider(11).future);

      expect(repository.detailIds, [10, 11]);
    });

    test('404: AsyncError con el mensaje del servidor', () async {
      final repository = FakeRecurringRepository(
        onDetail: (_) async => throw const ApiException(
          'El pago recurrente no existe.',
          statusCode: 404,
        ),
      );
      final container = _container(repository);
      keepAlive(container, [recurringDetailProvider(99)]);

      await expectLater(
        container.read(recurringDetailProvider(99).future),
        throwsA(isA<ApiException>()),
      );
      expect(
        userErrorMessage(container.read(recurringDetailProvider(99)).error),
        'El pago recurrente no existe.',
      );
    });
  });
}
