import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_movements_repository.dart';

const _income = MovementType.income;
const _expense = MovementType.expense;

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

DateTimeRange get _thisMonthRange => DateTimeRange(
  start: _thisMonth,
  end: DateTime(_thisMonth.year, _thisMonth.month + 1, 0),
);

ProviderContainer _container(FakeMovementsRepository repository) {
  final container = makeContainer(
    overrides: [movementsRepositoryProvider.overrideWithValue(repository)],
  );
  keepAlive(container, [
    movementsFilterProvider(_income),
    movementsListProvider(_income),
    filteredMovementsProvider(_income),
    filteredTotalProvider(_income),
    filteredEntriesProvider(_income),
  ]);
  return container;
}

/// Deja correr los microtasks para que el provider se reconstruya.
Future<void> _settle(ProviderContainer container) async {
  await Future<void>.delayed(Duration.zero);
  await container.pump();
}

void main() {
  group('movementsFilterProvider', () {
    test('empieza en el mes elegido, del día 1 al último', () {
      final container = _container(FakeMovementsRepository());
      final filter = container.read(movementsFilterProvider(_income));
      expect(filter.type, _income);
      expect(filter.range, _thisMonthRange);
      expect(filter.categoryId, isNull);
      expect(filter.methodId, isNull);
      expect(filter.query, '');
    });

    test('si el mes elegido es otro, empieza en ese mes', () {
      final container = makeContainer();
      container.read(selectedMonthProvider.notifier).previous();
      final previous = DateTime(_thisMonth.year, _thisMonth.month - 1);

      final filter = container.read(movementsFilterProvider(_expense));

      expect(filter.range.start, previous);
      expect(filter.range.end, DateTime(previous.year, previous.month + 1, 0));
    });

    test('cambiar de mes en la cabecera no mueve un filtro ya abierto', () {
      final container = makeContainer();
      final sub = container.listen(movementsFilterProvider(_income), (_, _) {});
      container.read(selectedMonthProvider.notifier).previous();

      expect(
        container.read(movementsFilterProvider(_income)).range,
        _thisMonthRange,
      );
      sub.close();
    });

    test('setRange / setCategory / setMethod / setQuery cambian solo eso', () {
      final container = _container(FakeMovementsRepository());
      final notifier = container.read(
        movementsFilterProvider(_income).notifier,
      );
      final range = DateTimeRange(
        start: DateTime(2026, 8, 3),
        end: DateTime(2026, 8, 9),
      );

      notifier.setRange(range);
      notifier.setCategory(9);
      notifier.setMethod(5);
      notifier.setQuery('sueldo');

      final filter = container.read(movementsFilterProvider(_income));
      expect(filter.range, range);
      expect(filter.categoryId, 9);
      expect(filter.methodId, 5);
      expect(filter.query, 'sueldo');
      expect(filter.type, _income);
    });

    test('setCategory(null) y setMethod(null) quitan solo su filtro', () {
      final container = _container(FakeMovementsRepository());
      final notifier = container.read(
        movementsFilterProvider(_income).notifier,
      );
      notifier.setCategory(9);
      notifier.setMethod(5);

      notifier.setCategory(null);
      expect(
        container.read(movementsFilterProvider(_income)).categoryId,
        isNull,
      );
      expect(container.read(movementsFilterProvider(_income)).methodId, 5);

      notifier.setMethod(null);
      expect(container.read(movementsFilterProvider(_income)).methodId, isNull);
    });

    test('reset vuelve al mes elegido sin categoría, medio ni texto', () {
      final container = _container(FakeMovementsRepository());
      final notifier = container.read(
        movementsFilterProvider(_income).notifier,
      );
      notifier.setRange(
        DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 2)),
      );
      notifier.setCategory(9);
      notifier.setMethod(5);
      notifier.setQuery('x');

      notifier.reset();

      final filter = container.read(movementsFilterProvider(_income));
      expect(filter.range, _thisMonthRange);
      expect(filter.categoryId, isNull);
      expect(filter.methodId, isNull);
      expect(filter.query, '');
      expect(filter.hasExtras, isFalse);
    });

    test('ingresos y gastos tienen filtros independientes', () {
      final container = _container(FakeMovementsRepository());
      container.read(movementsFilterProvider(_income).notifier).setQuery('a');

      expect(container.read(movementsFilterProvider(_expense)).query, '');
    });

    test(
      'autoDispose: al dejar de observarlo vuelve al mes completo',
      () async {
        final container = makeContainer(
          overrides: [
            movementsRepositoryProvider.overrideWithValue(
              FakeMovementsRepository(),
            ),
          ],
        );
        final sub = container.listen(
          movementsFilterProvider(_income),
          (_, _) {},
        );
        container.read(movementsFilterProvider(_income).notifier).setQuery('x');
        container
            .read(movementsFilterProvider(_income).notifier)
            .setCategory(3);
        expect(
          container.read(movementsFilterProvider(_income)).hasExtras,
          isTrue,
        );

        sub.close();
        await container.pump();

        final fresh = container.read(movementsFilterProvider(_income));
        expect(fresh.query, '');
        expect(fresh.categoryId, isNull);
      },
    );

    test(
      'autoDispose es por tipo: soltar ingresos no reinicia gastos',
      () async {
        final container = makeContainer();
        final income = container.listen(
          movementsFilterProvider(_income),
          (_, _) {},
        );
        final expense = container.listen(
          movementsFilterProvider(_expense),
          (_, _) {},
        );
        container.read(movementsFilterProvider(_income).notifier).setQuery('i');
        container
            .read(movementsFilterProvider(_expense).notifier)
            .setQuery('g');

        income.close();
        await container.pump();

        expect(container.read(movementsFilterProvider(_expense)).query, 'g');
        expense.close();
        await container.pump();
        expect(container.read(movementsFilterProvider(_income)).query, '');
      },
    );
  });

  group('movementsListProvider (datos del servidor)', () {
    test('pide el mes elegido con el tipo y sin categoría ni medio', () async {
      final repository = FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(id: 1, type: _income, date: dayOfCurrentMonth(1)),
          buildMovement(id: 2, type: _expense, date: dayOfCurrentMonth(1)),
        ],
      );
      final container = _container(repository);

      final items = await container.read(movementsListProvider(_income).future);

      expect(items.map((m) => m.id), [1]);
      expect(repository.searchCalls, 1);
      final (from, to) = repository.listedRanges.single;
      expect(from, _thisMonthRange.start);
      expect(to, _thisMonthRange.end);
    });

    test(
      'cambiar categoría o medio vuelve a pedir con esos parámetros',
      () async {
        final repository = FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(
              id: 1,
              type: _income,
              categoryId: 9,
              methodId: 5,
              date: dayOfCurrentMonth(1),
            ),
            buildMovement(
              id: 2,
              type: _income,
              categoryId: 8,
              methodId: 5,
              date: dayOfCurrentMonth(1),
            ),
            buildMovement(
              id: 3,
              type: _income,
              categoryId: 9,
              methodId: 6,
              date: dayOfCurrentMonth(1),
            ),
          ],
        );
        final container = _container(repository);
        final filter = container.read(
          movementsFilterProvider(_income).notifier,
        );
        await container.read(movementsListProvider(_income).future);

        filter.setCategory(9);
        await _settle(container);
        expect(
          (await container.read(movementsListProvider(_income).future))
              .map((m) => m.id),
          unorderedEquals([1, 3]),
        );

        filter.setMethod(5);
        await _settle(container);
        expect(
          (await container.read(movementsListProvider(_income).future))
              .map((m) => m.id),
          [1],
        );
        expect(repository.searchCalls, 3);
      },
    );

    test('cambiar el rango pide exactamente esas fechas', () async {
      final repository = FakeMovementsRepository();
      final container = _container(repository);
      await container.read(movementsListProvider(_income).future);

      container
          .read(movementsFilterProvider(_income).notifier)
          .setRange(
            DateTimeRange(
              start: DateTime(2026, 8, 3),
              end: DateTime(2026, 8, 9),
            ),
          );
      await _settle(container);
      await container.read(movementsListProvider(_income).future);

      expect(repository.listedRanges.last, (
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 9),
      ));
      expect(repository.searchCalls, 2);
    });

    test('escribir texto NO pide nada nuevo al servidor', () async {
      final repository = FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(
            id: 1,
            type: _income,
            description: 'Salario',
            date: dayOfCurrentMonth(1),
          ),
          buildMovement(
            id: 2,
            type: _income,
            description: 'Venta de moto',
            date: dayOfCurrentMonth(1),
          ),
        ],
      );
      final container = _container(repository);
      await container.read(movementsListProvider(_income).future);

      final notifier = container.read(
        movementsFilterProvider(_income).notifier,
      );
      notifier.setQuery('moto');
      await _settle(container);

      expect(repository.searchCalls, 1);
      expect(
        container
            .read(filteredMovementsProvider(_income))
            .value!
            .map((m) => m.id),
        [2],
      );
    });

    test('ordena el resultado: más reciente primero', () async {
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async => [
            buildMovement(id: 1, type: _income, date: dayOfCurrentMonth(1)),
            buildMovement(id: 2, type: _income, date: dayOfCurrentMonth(2)),
          ],
        ),
      );
      final items = await container.read(movementsListProvider(_income).future);
      expect(items.map((m) => m.id), [2, 1]);
    });

    test('cargando: AsyncLoading sin datos; luego los datos', () async {
      final completer = Completer<List<Movement>>();
      final container = _container(
        FakeMovementsRepository(onList: (_, _) => completer.future),
      );

      expect(
        container.read(filteredMovementsProvider(_income)).isLoading,
        isTrue,
      );
      expect(
        container.read(filteredMovementsProvider(_income)).hasValue,
        isFalse,
      );

      completer.complete([
        buildMovement(type: _income, date: dayOfCurrentMonth(1)),
      ]);
      await container.read(movementsListProvider(_income).future);
      expect(
        container.read(filteredMovementsProvider(_income)).value,
        hasLength(1),
      );
    });

    test('vacío: AsyncData con lista vacía, total 0 y sin líneas', () async {
      final container = _container(FakeMovementsRepository());
      await container.read(movementsListProvider(_income).future);

      expect(container.read(filteredMovementsProvider(_income)).value, isEmpty);
      expect(container.read(filteredTotalProvider(_income)), 0);
      expect(container.read(filteredEntriesProvider(_income)), isEmpty);
    });

    test('error: conserva el mensaje en español del repositorio', () async {
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async => throw const NetworkException('Sin conexión.'),
        ),
      );
      await expectLater(
        container.read(movementsListProvider(_income).future),
        throwsA(isA<NetworkException>()),
      );

      final state = container.read(filteredMovementsProvider(_income));
      expect(state.hasError, isTrue);
      expect((state.error! as NetworkException).message, 'Sin conexión.');
      expect(container.read(filteredTotalProvider(_income)), 0);
    });

    test(
      'cambiar de filtro conserva la lista anterior mientras carga',
      () async {
        var call = 0;
        final second = Completer<List<Movement>>();
        final container = _container(
          FakeMovementsRepository(
            onList: (_, _) {
              call++;
              return call == 1
                  ? Future.value([
                      buildMovement(
                        id: 1,
                        type: _income,
                        date: dayOfCurrentMonth(1),
                      ),
                      buildMovement(
                        id: 2,
                        type: _income,
                        date: dayOfCurrentMonth(2),
                      ),
                    ])
                  : second.future;
            },
          ),
        );
        await container.read(movementsListProvider(_income).future);

        container
            .read(movementsFilterProvider(_income).notifier)
            .setCategory(3);
        await _settle(container);

        // El valor anterior sigue en el notifier mientras llega el nuevo.
        final raw = container.read(movementsListProvider(_income));
        expect(raw.isLoading, isTrue, reason: 'está pidiendo la nueva');
        expect(raw.value, hasLength(2), reason: 'la lista vieja sigue');
        // Y lo que se pinta no se vacía.
        expect(
          container.read(filteredMovementsProvider(_income)).value,
          hasLength(2),
        );
        expect(container.read(filteredTotalProvider(_income)), 5000000);
        expect(container.read(filteredEntriesProvider(_income)), isNotEmpty);

        second.complete([
          buildMovement(id: 2, type: _income, date: dayOfCurrentMonth(2)),
        ]);
        await container.read(movementsListProvider(_income).future);
        expect(
          container.read(filteredMovementsProvider(_income)).value,
          hasLength(1),
        );
        expect(
          container.read(filteredMovementsProvider(_income)).isLoading,
          isFalse,
        );
      },
    );

    test('si el filtro nuevo falla, la lista anterior no se pierde', () async {
      var call = 0;
      final container = _container(
        FakeMovementsRepository(
          onList: (_, _) async {
            if (++call == 1) {
              return [
                buildMovement(id: 1, type: _income, date: dayOfCurrentMonth(1)),
              ];
            }
            throw const NetworkException('Sin conexión.');
          },
        ),
      );
      await container.read(movementsListProvider(_income).future);

      container.read(movementsFilterProvider(_income).notifier).setMethod(5);
      await _settle(container);
      await _settle(container);

      // El notifier sí distingue «error con datos previos»...
      final raw = container.read(movementsListProvider(_income));
      expect(raw.hasError, isTrue);
      expect(raw.value, hasLength(1), reason: 'sigue la lista que se veía');
      // ...y lo que se pinta no se vacía.
      expect(
        container.read(filteredMovementsProvider(_income)).value,
        hasLength(1),
      );
    });

    // DEFECTO REAL (ver informe): mapKeepingData devuelve AsyncData en cuanto
    // hay valor, así que filteredMovementsProvider pierde isLoading/hasError
    // al cambiar de filtro: la pantalla no muestra la barra fina de recarga y,
    // si la consulta falla, enseña la lista del filtro anterior como si fuera
    // la del nuevo, sin aviso. Se activa cuando se corrija en lib/.
    test(
      'el estado que se pinta avisa que recarga y que falló con datos previos',
      () async {
        var call = 0;
        final second = Completer<List<Movement>>();
        final container = _container(
          FakeMovementsRepository(
            onList: (_, _) {
              call++;
              if (call == 1) {
                return Future.value([
                  buildMovement(
                    id: 1,
                    type: _income,
                    date: dayOfCurrentMonth(1),
                  ),
                ]);
              }
              return call == 2 ? second.future : Future.error(StateError('x'));
            },
          ),
        );
        await container.read(movementsListProvider(_income).future);

        container.read(movementsFilterProvider(_income).notifier).setMethod(5);
        await _settle(container);
        expect(
          container.read(filteredMovementsProvider(_income)).isLoading,
          isTrue,
          reason: 'debe verse la barra fina mientras llega el filtro nuevo',
        );

        second.completeError(const NetworkException('Sin conexión.'));
        await _settle(container);
        expect(
          container.read(filteredMovementsProvider(_income)).hasError,
          isTrue,
          reason: 'un filtro que falla no puede mostrar la lista vieja callada',
        );
      },
    );

    test(
      'el total y las líneas salen de las mismas filas que se ven',
      () async {
        final container = _container(
          FakeMovementsRepository(
            onList: (_, _) async => [
              buildMovement(
                id: 1,
                type: _income,
                valueCents: 100000,
                description: 'Salario',
                date: dayOfCurrentMonth(1),
              ),
              buildMovement(
                id: 2,
                type: _income,
                valueCents: 250000,
                description: 'Venta',
                date: dayOfCurrentMonth(1),
              ),
            ],
          ),
        );
        await container.read(movementsListProvider(_income).future);
        expect(container.read(filteredTotalProvider(_income)), 350000);
        expect(
          container
              .read(filteredEntriesProvider(_income))
              .whereType<MovementRowEntry>(),
          hasLength(2),
        );

        container
            .read(movementsFilterProvider(_income).notifier)
            .setQuery('venta');
        // El texto se aplica en el notifier derivado: espera a que reconstruya.
        await container.read(filteredMovementsProvider(_income).future);
        await _settle(container);

        expect(container.read(filteredTotalProvider(_income)), 250000);
        expect(
          container
              .read(filteredEntriesProvider(_income))
              .whereType<MovementRowEntry>(),
          hasLength(1),
        );
        final header = container
            .read(filteredEntriesProvider(_income))
            .whereType<DayHeaderEntry>()
            .single;
        expect(header.totalCents, 250000);
      },
    );

    test(
      'autoDispose: sin observadores, volver a abrir pide otra vez',
      () async {
        final repository = FakeMovementsRepository();
        final container = makeContainer(
          overrides: [
            movementsRepositoryProvider.overrideWithValue(repository),
          ],
        );
        var sub = container.listen(movementsListProvider(_income), (_, _) {});
        await container.read(movementsListProvider(_income).future);
        sub.close();
        await container.pump();

        sub = container.listen(movementsListProvider(_income), (_, _) {});
        await container.read(movementsListProvider(_income).future);

        expect(repository.searchCalls, 2);
        sub.close();
      },
    );

    test('al cambiar de cuenta se vuelve a pedir la lista', () async {
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
      keepAlive(container, [movementsListProvider(_income)]);
      await container.read(movementsListProvider(_income).future);
      expect(repository.searchCalls, 1);

      container.read(sessionProvider.notifier).open(buildSession(id: 2));
      await _settle(container);
      await container.read(movementsListProvider(_income).future);

      expect(repository.searchCalls, 2);
    });
  });
}
