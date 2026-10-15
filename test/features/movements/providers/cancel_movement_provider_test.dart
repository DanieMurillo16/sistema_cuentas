import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/cancel_movement_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/fake_recurring_repository.dart';
import '../../../support/recurring_harness.dart';

Movement _gasto({
  int id = 1,
  bool fromRecurring = false,
  MovementType type = MovementType.expense,
}) => buildMovement(
  id: id,
  type: type,
  date: dayOfCurrentMonth(1),
  fromRecurring: fromRecurring,
);

/// Los repositorios falsos con tres movimientos (dos gastos y un ingreso) y las
/// vistas que tendría abiertas la app.
RecurringHarness _harness({
  Future<void> Function(int id, String reason)? cancel,
  Future<List<Movement>> Function(DateTime, DateTime)? list,
}) {
  final h = RecurringHarness(
    movements: FakeMovementsRepository(
      onList:
          list ??
          (_, _) async => [
            _gasto(id: 1),
            _gasto(id: 2),
            _gasto(id: 3, type: MovementType.income),
          ],
      onCancel: cancel,
    ),
    recurring: FakeRecurringRepository(
      onList: () async => [buildRecurring(id: 10)],
      onDetail: (id) async => buildDetail(payment: buildRecurring(id: id)),
    ),
  );
  keepAlive(h.container, [cancelMovementProvider]);
  return h;
}

AsyncValue<void> _state(RecurringHarness h) =>
    h.container.read(cancelMovementProvider);

Future<void> _cancel(
  RecurringHarness h,
  Movement movement, {
  String reason = 'Registrado por error',
}) => h.container
    .read(cancelMovementProvider.notifier)
    .cancel(movement, reason: reason);

List<int> _ids(RecurringHarness h) =>
    h.container.read(movementsProvider).requireValue.map((m) => m.id).toList();

void main() {
  test('estado inicial: en reposo', () {
    final h = _harness();
    expect(_state(h).isLoading, isFalse);
    expect(_state(h).hasError, isFalse);
  });

  test('éxito: manda id y motivo al repositorio y quita la fila de la lista '
      'sin recargarla', () async {
    final h = _harness();
    await h.openViews();

    await _cancel(h, _gasto(id: 2));

    expect(_state(h).hasError, isFalse);
    expect(_state(h).isLoading, isFalse);
    expect(h.movements.cancelCalls, 1);
    expect(h.movements.cancelled.single, (
      id: 2,
      reason: 'Registrado por error',
    ));
    expect(_ids(h), containsAll([1, 3]));
    expect(_ids(h), isNot(contains(2)));
    expect(h.movements.listCalls, 1, reason: 'la lista no se recarga entera');
  });

  test('el motivo se manda sin espacios sobrantes', () async {
    final h = _harness();
    await h.openViews();

    await _cancel(h, _gasto(), reason: '   Duplicado   ');

    expect(h.movements.cancelled.single.reason, 'Duplicado');
  });

  test(
    'éxito: el resumen del mes se vuelve a pedir (el servidor recalcula)',
    () async {
      final h = _harness();
      await h.openViews();
      expect(h.summary.calls, 1);

      await _cancel(h, _gasto());
      final calls = await h.settleViews();

      expect(calls.summary, 2);
    },
  );

  test('otra vista (Inicio) deja de ver la fila sin recargar', () async {
    final h = _harness();
    keepAlive(h.container, [homeEntriesProvider]);
    await h.openViews();
    List<int> rows() => h.container
        .read(homeEntriesProvider)
        .whereType<MovementRowEntry>()
        .map((e) => e.movement.id)
        .toList();
    expect(rows(), containsAll([1, 2, 3]));

    await _cancel(h, _gasto(id: 2));

    expect(rows(), isNot(contains(2)));
    expect(rows(), hasLength(2));
  });

  group('lista de Ingresos/Gastos (movementsListProvider)', () {
    test('si está abierta, quita la fila sin volver a pedirla', () async {
      final h = _harness();
      await h.openViews();
      keepAlive(h.container, [movementsListProvider(MovementType.expense)]);
      final before = await h.container.read(
        movementsListProvider(MovementType.expense).future,
      );
      expect(before.map((m) => m.id), containsAll([1, 2]));
      expect(h.movements.searchCalls, 1);

      await _cancel(h, _gasto(id: 1));

      final after = h.container
          .read(movementsListProvider(MovementType.expense))
          .requireValue;
      expect(after.map((m) => m.id), [2]);
      expect(h.movements.searchCalls, 1, reason: 'no se volvió a pedir');
    });

    test('solo toca la lista del tipo de la fila', () async {
      final h = _harness();
      await h.openViews();
      keepAlive(h.container, [movementsListProvider(MovementType.income)]);
      await h.container.read(movementsListProvider(MovementType.income).future);

      await _cancel(h, _gasto(id: 1));

      expect(
        h.container
            .read(movementsListProvider(MovementType.income))
            .requireValue
            .map((m) => m.id),
        [3],
      );
    });

    test('si no está abierta, no se crea ni se pide', () async {
      final h = _harness();
      await h.openViews();

      await _cancel(h, _gasto(id: 1));

      expect(h.movements.searchCalls, 0);
    });

    test(
      'si todavía carga (sin valor), se invalida en vez de quitar la fila',
      () async {
        final pending = Completer<List<Movement>>();
        var searches = 0;
        final h = _harness(
          list: (_, _) {
            searches++;
            // La primera consulta de la lista queda pendiente (la de movementsProvider es otra).
            return searches == 2
                ? pending.future
                : Future.value([_gasto(id: 1), _gasto(id: 2)]);
          },
        );
        await h.openViews();
        keepAlive(h.container, [movementsListProvider(MovementType.expense)]);
        h.container.read(movementsListProvider(MovementType.expense));
        await Future<void>.delayed(Duration.zero);
        expect(
          h.container
              .read(movementsListProvider(MovementType.expense))
              .hasValue,
          isFalse,
        );

        await _cancel(h, _gasto(id: 1));
        await Future<void>.delayed(Duration.zero);

        // Se vuelve a pedir (3.ª consulta) y llega ya sin que se haya quitado a mano.
        expect(searches, 3);
        pending.complete([_gasto(id: 1)]);
      },
    );
  });

  test(
    'si la lista del mes aún no tiene valor, se invalida y se vuelve a pedir',
    () async {
      final pending = Completer<List<Movement>>();
      var calls = 0;
      final h = _harness(
        list: (_, _) {
          calls++;
          return calls == 1 ? pending.future : Future.value([_gasto(id: 2)]);
        },
      );
      keepAlive(h.container, [movementsProvider]);
      h.container.read(movementsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(h.container.read(movementsProvider).hasValue, isFalse);

      await _cancel(h, _gasto(id: 1));
      final items = await h.container.read(movementsProvider.future);

      expect(calls, 2, reason: 'se volvió a pedir');
      expect(items.map((m) => m.id), [2]);
      pending.complete(const []);
    },
  );

  group('dependientes de un acuerdo recurrente', () {
    test('un movimiento que NO viene de un acuerdo no invalida vencimientos, '
        'acuerdos ni detalle', () async {
      final h = _harness();
      await h.openViews(detailId: 10);

      await _cancel(h, _gasto());
      final calls = await h.settleViews(detailId: 10);

      expect(calls.dues, 1);
      expect(calls.list, 1);
      expect(calls.detail, 1);
      expect(calls.summary, 2, reason: 'el resumen sí');
    });

    test('un movimiento que viene de un acuerdo invalida vencimientos, '
        'lista de acuerdos y su detalle', () async {
      final h = _harness();
      await h.openViews(detailId: 10);

      await _cancel(h, _gasto(fromRecurring: true));
      final calls = await h.settleViews(detailId: 10);

      expect(calls.dues, 2, reason: 'el vencimiento vuelve a deber');
      expect(calls.list, 2, reason: 'el acuerdo cambia de saldo');
      expect(calls.detail, 2, reason: 'el historial del acuerdo');
      expect(calls.summary, 2);
      expect(
        calls.movements,
        1,
        reason: 'la lista de movimientos no se recarga',
      );
    });
  });

  test(
    'anti doble envío: un segundo cancel mientras elimina no llama otra vez',
    () async {
      final completer = Completer<void>();
      final h = _harness(cancel: (_, _) => completer.future);
      await h.openViews();
      final notifier = h.container.read(cancelMovementProvider.notifier);

      final first = notifier.cancel(_gasto(), reason: 'Duplicado');
      expect(_state(h).isLoading, isTrue);
      await notifier.cancel(_gasto(), reason: 'Duplicado');
      await notifier.cancel(_gasto(id: 2), reason: 'Duplicado');
      expect(h.movements.cancelCalls, 1);

      completer.complete();
      await first;
      expect(_state(h).isLoading, isFalse);
      expect(h.movements.cancelCalls, 1);
    },
  );

  test('mientras elimina la fila sigue en la lista', () async {
    final completer = Completer<void>();
    final h = _harness(cancel: (_, _) => completer.future);
    await h.openViews();

    final pending = _cancel(h, _gasto(id: 2));
    await Future<void>.delayed(Duration.zero);

    expect(_ids(h), contains(2));
    completer.complete();
    await pending;
    expect(_ids(h), isNot(contains(2)));
  });

  group('error del servidor', () {
    Future<RecurringHarness> failing({String code = 'YA_ANULADO'}) async {
      final h = _harness(
        cancel: (_, _) async => throw ApiException(
          'El movimiento ya está anulado.',
          code: code,
          statusCode: 422,
        ),
      );
      await h.openViews(detailId: 10);
      keepAlive(h.container, [movementsListProvider(MovementType.expense)]);
      await h.container.read(
        movementsListProvider(MovementType.expense).future,
      );
      return h;
    }

    test('queda en AsyncError con el mensaje en español', () async {
      final h = await failing();

      await _cancel(h, _gasto(id: 2, fromRecurring: true));

      expect(_state(h).hasError, isTrue);
      expect(_state(h).isLoading, isFalse);
      expect(
        userErrorMessage(_state(h).error),
        'El movimiento ya está anulado.',
      );
    });

    test('NO quita la fila de ninguna lista', () async {
      final h = await failing();

      await _cancel(h, _gasto(id: 2, fromRecurring: true));

      expect(_ids(h), containsAll([1, 2, 3]));
      expect(
        h.container
            .read(movementsListProvider(MovementType.expense))
            .requireValue
            .map((m) => m.id),
        containsAll([1, 2]),
      );
    });

    test(
      'NO invalida nada: ni resumen, ni vencimientos, ni acuerdos',
      () async {
        final h = await failing();
        final searchesBefore = h.movements.searchCalls;
        final listBefore = h.movements.listCalls;

        await _cancel(h, _gasto(id: 2, fromRecurring: true));
        final calls = await h.settleViews(detailId: 10);

        expect(calls.summary, 1);
        expect(calls.dues, 1);
        expect(calls.list, 1);
        expect(calls.detail, 1);
        expect(calls.movements, listBefore, reason: 'ninguna lista se recarga');
        expect(h.movements.searchCalls, searchesBefore);
      },
    );

    test('sin conexión: el mensaje de red en español', () async {
      final h = _harness(
        cancel: (_, _) async => throw const NetworkException(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        ),
      );
      await h.openViews();

      await _cancel(h, _gasto());

      expect(
        userErrorMessage(_state(h).error),
        'No fue posible conectar con el servidor. Revisa tu conexión.',
      );
      expect(_ids(h), contains(1));
    });

    test('tras un error se puede volver a intentar', () async {
      var attempt = 0;
      final h = _harness(
        cancel: (_, _) async {
          attempt++;
          if (attempt == 1) throw const NetworkException('Sin conexión.');
        },
      );
      await h.openViews();

      await _cancel(h, _gasto(id: 2));
      expect(_state(h).hasError, isTrue);

      await _cancel(h, _gasto(id: 2));
      expect(_state(h).hasError, isFalse);
      expect(h.movements.cancelCalls, 2);
      expect(_ids(h), isNot(contains(2)));
    });
  });

  test('si nadie observa al notifier (diálogo cerrado), la eliminación '
      'termina y la app se entera igual', () async {
    final completer = Completer<void>();
    final h = RecurringHarness(
      movements: FakeMovementsRepository(
        onList: (_, _) async => [_gasto(id: 1), _gasto(id: 2)],
        onCancel: (_, _) => completer.future,
      ),
    );
    await h.openViews();
    // Sin keepAlive(cancelMovementProvider): como un diálogo que ya se cerró.
    final pending = h.container
        .read(cancelMovementProvider.notifier)
        .cancel(_gasto(id: 2), reason: 'Duplicado');
    await Future<void>.delayed(Duration.zero);

    completer.complete();
    await pending;

    expect(_ids(h), [1]);
    expect((await h.settleViews()).summary, 2);
  });
}
