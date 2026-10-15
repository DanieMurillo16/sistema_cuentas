import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/delete_recurring_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_dues_repository.dart';
import '../../../support/fake_recurring_repository.dart';
import '../../../support/recurring_harness.dart';

/// Dos acuerdos (10 y 11), cada uno con su vencimiento del mes. El «servidor»
/// deja de listar los vencimientos de un acuerdo finalizado.
class _Server {
  _Server({this.finish});

  final Future<void> Function(int id)? finish;
  final dues = <Due>[
    buildDue(id: 1, recurringId: 10, description: 'Arriendo'),
    buildDue(id: 2, recurringId: 11, description: 'Gimnasio'),
  ];
  final finishedIds = <int>{};

  late final harness = RecurringHarness(
    dues: FakeDuesRepository(
      (_) async => buildDuesMonth([
        for (final d in dues)
          if (!finishedIds.contains(d.recurringId)) d,
      ]),
    ),
    recurring: FakeRecurringRepository(
      onList: () async => [
        buildRecurring(id: 10, description: 'Arriendo'),
        buildRecurring(id: 11, description: 'Gimnasio'),
      ],
      onDetail: (id) async => buildDetail(payment: buildRecurring(id: id)),
      onDelete: (id) async {
        await finish?.call(id);
        finishedIds.add(id);
      },
    ),
  );

  RecurringHarness get h => harness;
}

AsyncValue<void> _state(RecurringHarness h) =>
    h.container.read(deleteRecurringProvider);

Future<RecurringHarness> _open(_Server server) async {
  final h = server.h;
  keepAlive(h.container, [deleteRecurringProvider]);
  await h.openViews(detailId: 10);
  return h;
}

List<int> _recurringIds(RecurringHarness h) => h.container
    .read(recurringListProvider)
    .requireValue
    .map((p) => p.id)
    .toList();

List<int> _dueIds(RecurringHarness h) =>
    h.container.read(duesProvider).requireValue.dues.map((d) => d.id).toList();

Future<void> _delete(RecurringHarness h, int id) =>
    h.container.read(deleteRecurringProvider.notifier).delete(id);

void main() {
  test('estado inicial: en reposo', () async {
    final h = await _open(_Server());
    expect(_state(h).isLoading, isFalse);
    expect(_state(h).hasError, isFalse);
  });

  test('éxito: manda solo el id al endpoint de eliminar', () async {
    final h = await _open(_Server());

    await _delete(h, 10);

    expect(_state(h).hasError, isFalse);
    expect(h.recurring.deleteCalls, 1);
    expect(h.recurring.deleted, [10]);
    expect(
      h.recurring.finishCalls,
      0,
      reason: 'eliminar ya no es «finalizar» con una nota fija',
    );
  });

  test(
    'éxito: el acuerdo y sus vencimientos salen de las dos listas',
    () async {
      final h = await _open(_Server());
      expect(_recurringIds(h), [10, 11]);
      expect(_dueIds(h), [1, 2]);

      await _delete(h, 10);
      await h.settleViews(detailId: 10);

      expect(_dueIds(h), [2], reason: 'solo queda el del otro acuerdo');
      expect(_recurringIds(h), contains(11));
    },
  );

  test('sale de las listas YA, sin esperar la recarga', () async {
    final server = _Server();
    final h = await _open(server);
    // Desde ahora, recargar tarda: lo que se ve debe estar ya sin el acuerdo.
    final pendingDues = Completer<DuesMonth>();
    h.dues.onMonth = (_) => pendingDues.future;
    final pendingList = Completer<List<dynamic>>();
    h.recurring.onList = () async => (await pendingList.future).cast();

    await _delete(h, 10);

    expect(_dueIds(h), [2]);
    expect(_recurringIds(h), [11]);
    expect(
      h.container.read(duesProvider).requireValue.totals,
      isNotEmpty,
      reason: 'los totales se conservan hasta que llega la recarga',
    );
    pendingDues.complete(buildDuesMonth([server.dues[1]]));
    pendingList.complete([buildRecurring(id: 11)]);
    await h.settleViews(detailId: 10);
  });

  test('éxito: invalida lista, vencimientos, movimientos, resumen y el detalle '
      'de ESE acuerdo', () async {
    final h = await _open(_Server());
    keepAliveDetail(h, 11);
    await h.container.read(recurringDetailProvider(11).future);
    expect(
      (
        h.recurring.listCalls,
        h.dues.calls,
        h.movements.listCalls,
        h.summary.calls,
      ),
      (1, 1, 1, 1),
    );

    await _delete(h, 10);
    final calls = await h.settleViews(detailId: 10);

    expect(calls.list, 2);
    expect(calls.dues, 2);
    expect(calls.movements, 2);
    expect(calls.summary, 2);
    expect(calls.detail, 3, reason: '10 y 11 al abrir, 10 otra vez');
    expect(h.recurring.detailIds, [10, 11, 10]);
  });

  test(
    'anti doble envío: un segundo delete mientras elimina no llama otra vez',
    () async {
      final gate = Completer<void>();
      final h = await _open(_Server(finish: (_) => gate.future));
      final notifier = h.container.read(deleteRecurringProvider.notifier);

      final first = notifier.delete(10);
      expect(_state(h).isLoading, isTrue);
      await notifier.delete(10);
      await notifier.delete(11);
      expect(h.recurring.deleteCalls, 1);

      gate.complete();
      await first;
      expect(_state(h).isLoading, isFalse);
      expect(h.recurring.deleteCalls, 1);
    },
  );

  group('error del servidor', () {
    Future<RecurringHarness> failing() => _open(
      _Server(
        finish: (_) async => throw const ApiException(
          'Este pago recurrente ya está finalizado.',
          code: 'YA_FINALIZADO',
          statusCode: 422,
        ),
      ),
    );

    test('queda en AsyncError con el mensaje en español', () async {
      final h = await failing();

      await _delete(h, 10);

      expect(_state(h).hasError, isTrue);
      expect(
        userErrorMessage(_state(h).error),
        'Este pago recurrente ya está finalizado.',
      );
    });

    test('NO quita nada de las listas', () async {
      final h = await failing();

      await _delete(h, 10);

      expect(_recurringIds(h), [10, 11]);
      expect(_dueIds(h), [1, 2]);
    });

    test('NO invalida nada', () async {
      final h = await failing();

      await _delete(h, 10);
      final calls = await h.settleViews(detailId: 10);

      expect(
        (calls.list, calls.dues, calls.movements, calls.summary, calls.detail),
        (1, 1, 1, 1, 1),
      );
    });

    test('tras un error se puede volver a intentar', () async {
      var attempt = 0;
      final h = await _open(
        _Server(
          finish: (_) async {
            attempt++;
            if (attempt == 1) throw const NetworkException('Sin conexión.');
          },
        ),
      );

      await _delete(h, 10);
      expect(_state(h).hasError, isTrue);
      await _delete(h, 10);

      expect(_state(h).hasError, isFalse);
      expect(h.recurring.deleteCalls, 2);
      expect(_dueIds(h), [2]);
    });
  });

  test(
    'si nadie observa al notifier (diálogo cerrado) termina igual',
    () async {
      final gate = Completer<void>();
      final h = _Server(finish: (_) => gate.future).h;
      await h.openViews(detailId: 10);
      // Sin keepAlive(deleteRecurringProvider): como un diálogo ya cerrado.
      final pending = _delete(h, 10);
      await Future<void>.delayed(Duration.zero);

      gate.complete();
      await pending;

      expect(_dueIds(h), [2]);
      expect(_recurringIds(h), [11]);
    },
  );
}

void keepAliveDetail(RecurringHarness h, int id) =>
    keepAlive(h.container, [recurringDetailProvider(id)]);
