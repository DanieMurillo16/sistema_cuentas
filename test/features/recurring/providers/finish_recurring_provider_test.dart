import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/providers/finish_recurring_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_recurring_repository.dart';
import '../../../support/recurring_harness.dart';

FinishDraft _draft({int recurringId = 10, int? capital, int? method}) =>
    FinishDraft(
      recurringId: recurringId,
      endDate: DateTime(2026, 10, 13),
      closingNote: 'Se mudó',
      capitalPesos: capital,
      methodId: method,
    );

RecurringHarness _harness({Future<void> Function(FinishDraft draft)? finish}) {
  final h = RecurringHarness(
    recurring: FakeRecurringRepository(
      onList: () async => [buildRecurring(id: 10)],
      onDetail: (id) async => buildDetail(payment: buildRecurring(id: id)),
      onFinish: finish,
    ),
  );
  keepAlive(h.container, [finishRecurringProvider]);
  return h;
}

AsyncValue<void> _state(RecurringHarness h) =>
    h.container.read(finishRecurringProvider);

void main() {
  test('estado inicial: en reposo', () {
    final h = _harness();
    expect(_state(h).isLoading, isFalse);
    expect(_state(h).hasError, isFalse);
  });

  test('éxito: manda el borrador de cierre al repositorio', () async {
    final h = _harness();
    await h.openViews(detailId: 10);

    await h.container
        .read(finishRecurringProvider.notifier)
        .finish(_draft(capital: 2000000, method: 5));

    expect(_state(h).hasError, isFalse);
    expect(h.recurring.finishCalls, 1);
    expect(h.recurring.finished.single.recurringId, 10);
    expect(h.recurring.finished.single.capitalPesos, 2000000);
    expect(h.recurring.finished.single.methodId, 5);
  });

  test('éxito: invalida la lista, el detalle, los vencimientos, los movimientos y el resumen', () async {
    final h = _harness();
    await h.openViews(detailId: 10);
    expect(
      (
        h.recurring.listCalls,
        h.recurring.detailCalls,
        h.dues.calls,
        h.movements.listCalls,
        h.summary.calls,
      ),
      (1, 1, 1, 1, 1),
    );

    await h.container.read(finishRecurringProvider.notifier).finish(_draft());
    final calls = await h.settleViews(detailId: 10);

    expect(calls.list, 2, reason: 'el acuerdo pasa a finalizado');
    expect(calls.detail, 2, reason: 'ficha con fecha y motivo de cierre');
    expect(calls.dues, 2, reason: 'lo pendiente quedó omitido');
    expect(calls.movements, 2, reason: 'puede haber un movimiento de capital');
    expect(calls.summary, 2, reason: 'el balance del mes cambió');
  });

  test('éxito: el detalle de OTRO acuerdo no se vuelve a pedir', () async {
    final h = _harness();
    await h.openViews(detailId: 10);
    keepAlive(h.container, [recurringDetailProvider(11)]);
    await h.container.read(recurringDetailProvider(11).future);

    await h.container.read(finishRecurringProvider.notifier).finish(_draft());
    await h.settleViews(detailId: 10);

    expect(h.recurring.detailIds, [10, 11, 10]);
  });

  test(
    'anti doble envío: un segundo finish mientras guarda no llama otra vez',
    () async {
      final completer = Completer<void>();
      final h = _harness(finish: (_) => completer.future);
      await h.openViews(detailId: 10);
      final notifier = h.container.read(finishRecurringProvider.notifier);

      final first = notifier.finish(_draft());
      expect(_state(h).isLoading, isTrue);
      await notifier.finish(_draft());
      await notifier.finish(_draft());
      expect(h.recurring.finishCalls, 1);

      completer.complete();
      await first;
      expect(_state(h).isLoading, isFalse);
      expect(h.recurring.finishCalls, 1);
    },
  );

  test('error: queda en AsyncError y NO invalida nada', () async {
    final h = _harness(
      finish: (_) async => throw const ApiException(
        'Este pago recurrente ya fue finalizado.',
        code: 'YA_FINALIZADO',
        statusCode: 409,
      ),
    );
    await h.openViews(detailId: 10);

    await h.container.read(finishRecurringProvider.notifier).finish(_draft());
    final calls = await h.settleViews(detailId: 10);

    expect(_state(h).hasError, isTrue);
    expect(_state(h).isLoading, isFalse);
    expect(
      userErrorMessage(_state(h).error),
      'Este pago recurrente ya fue finalizado.',
    );
    expect(calls.list, 1);
    expect(calls.detail, 1);
    expect(calls.dues, 1);
    expect(calls.movements, 1);
    expect(calls.summary, 1);
  });

  test('tras un error se puede reintentar', () async {
    var attempt = 0;
    final h = _harness(
      finish: (_) async {
        attempt++;
        if (attempt == 1) throw const NetworkException('Sin conexión.');
      },
    );
    await h.openViews(detailId: 10);
    final notifier = h.container.read(finishRecurringProvider.notifier);

    await notifier.finish(_draft());
    expect(_state(h).hasError, isTrue);

    await notifier.finish(_draft());
    expect(_state(h).hasError, isFalse);
    expect(h.recurring.finishCalls, 2);
  });

  test(
    'si se cierra el diálogo mientras guarda, igual se invalida lo viejo',
    () async {
      final completer = Completer<void>();
      final h = RecurringHarness(
        recurring: FakeRecurringRepository(
          onList: () async => [buildRecurring(id: 10)],
          onFinish: (_) => completer.future,
        ),
      );
      await h.openViews();

      final finishing = h.container
          .read(finishRecurringProvider.notifier)
          .finish(_draft());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      completer.complete();
      await finishing;
      await h.settleViews();

      expect(h.recurring.listCalls, 2);
      expect(h.dues.calls, 2);
    },
  );
}
