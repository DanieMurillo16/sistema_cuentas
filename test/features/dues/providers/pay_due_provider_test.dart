import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/providers/pay_due_provider.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/features/movements/models/due_payment_draft.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/recurring_harness.dart';

DuePaymentDraft _draft({int dueId = 1, int recurringId = 10}) =>
    DuePaymentDraft(
      dueId: dueId,
      recurringId: recurringId,
      type: MovementType.income,
      amountPesos: 180000,
      date: dayOfCurrentMonth(1),
      methodId: 5,
    );

Movement _paid({int id = 99, DateTime? date}) => buildMovement(
  id: id,
  type: MovementType.income,
  valueCents: 18000000,
  date: date ?? dayOfCurrentMonth(1),
  description: 'Arriendo de Oscar',
);

RecurringHarness _harness({
  Future<Movement> Function(DuePaymentDraft draft)? register,
}) {
  final h = RecurringHarness(
    movements: FakeMovementsRepository(
      onList: (_, _) async => const [],
      onRegisterDue: register ?? (_) async => _paid(),
    ),
  );
  keepAlive(h.container, [payDueProvider]);
  return h;
}

AsyncValue<void> _state(RecurringHarness h) => h.container.read(payDueProvider);

void main() {
  test('estado inicial: en reposo, sin cargar ni error', () {
    final h = _harness();
    expect(_state(h).isLoading, isFalse);
    expect(_state(h).hasError, isFalse);
  });

  test('éxito: manda el borrador del vencimiento al repositorio', () async {
    final h = _harness();
    await h.openViews(detailId: 10);

    await h.container.read(payDueProvider.notifier).pay(_draft(dueId: 21));

    expect(_state(h).hasError, isFalse);
    expect(_state(h).isLoading, isFalse);
    expect(h.movements.registerDueCalls, 1);
    expect(h.movements.dueDrafts.single.dueId, 21);
    expect(h.movements.dueDrafts.single.amountPesos, 180000);
    expect(h.movements.registerCalls, 0, reason: 'no usa el registro suelto');
  });

  test(
    'éxito: el movimiento aparece en la lista de Inicio sin recargarla',
    () async {
      final h = _harness();
      await h.openViews(detailId: 10);
      keepAlive(h.container, [homeEntriesProvider]);
      expect(h.container.read(homeEntriesProvider), isEmpty);

      await h.container.read(payDueProvider.notifier).pay(_draft());

      final rows = h.container
          .read(homeEntriesProvider)
          .whereType<MovementRowEntry>();
      expect(rows.single.movement.id, 99);
      expect(
        h.container.read(movementsProvider).requireValue.map((m) => m.id),
        [99],
      );
      expect(h.movements.listCalls, 1, reason: 'upsert, no recarga entera');
    },
  );

  test('éxito: invalida vencimientos, resumen, acuerdos y el detalle de ESE acuerdo', () async {
    final h = _harness();
    await h.openViews(detailId: 10);
    expect(
      (
        h.dues.calls,
        h.summary.calls,
        h.recurring.listCalls,
        h.recurring.detailCalls,
      ),
      (1, 1, 1, 1),
    );

    await h.container
        .read(payDueProvider.notifier)
        .pay(_draft(recurringId: 10));
    final calls = await h.settleViews(detailId: 10);

    expect(calls.dues, 2, reason: 'los saldos del mes quedaron viejos');
    expect(calls.summary, 2, reason: 'el balance del mes cambió');
    expect(calls.list, 2, reason: 'total pagado y próximo vencimiento');
    expect(calls.detail, 2, reason: 'el historial del acuerdo');
    expect(h.recurring.detailIds, [10, 10]);
  });

  test('el detalle de OTRO acuerdo no se vuelve a pedir', () async {
    final h = _harness();
    await h.openViews(detailId: 10);
    keepAlive(h.container, [recurringDetailProvider(11)]);
    await h.container.read(recurringDetailProvider(11).future);
    expect(h.recurring.detailIds, [10, 11]);

    await h.container
        .read(payDueProvider.notifier)
        .pay(_draft(recurringId: 10));
    await h.settleViews(detailId: 10);

    expect(h.recurring.detailIds, [10, 11, 10]);
  });

  test(
    'un pago de otro mes se registra pero no entra a la lista del mes',
    () async {
      final now = DateTime.now();
      final h = _harness(
        register: (_) async =>
            _paid(id: 5, date: DateTime(now.year, now.month - 1, 20)),
      );
      await h.openViews();

      await h.container.read(payDueProvider.notifier).pay(_draft());

      expect(_state(h).hasError, isFalse);
      expect(h.container.read(movementsProvider).requireValue, isEmpty);
    },
  );

  test(
    'anti doble envío: un segundo pay mientras guarda no llama otra vez',
    () async {
      final completer = Completer<Movement>();
      final h = _harness(register: (_) => completer.future);
      await h.openViews();
      final notifier = h.container.read(payDueProvider.notifier);

      final first = notifier.pay(_draft());
      expect(_state(h).isLoading, isTrue);
      await notifier.pay(_draft());
      await notifier.pay(_draft());
      expect(h.movements.registerDueCalls, 1);

      completer.complete(_paid());
      await first;
      expect(_state(h).isLoading, isFalse);
      expect(h.movements.registerDueCalls, 1);
    },
  );

  test(
    'error: queda en AsyncError con el mensaje y NO se trata como éxito',
    () async {
      final h = _harness(
        register: (_) async => throw const ApiException(
          'El valor supera el saldo del vencimiento.',
          code: 'VALOR_EXCEDE_SALDO',
          statusCode: 422,
        ),
      );
      await h.openViews(detailId: 10);

      await h.container.read(payDueProvider.notifier).pay(_draft());

      // En Riverpod 3 un AsyncError conserva el valor anterior (hasValue sigue
      // siendo true): el éxito se decide por hasError/isLoading, nunca por hasValue.
      expect(_state(h).hasError, isTrue);
      expect(_state(h).isLoading, isFalse);
      expect(
        userErrorMessage(_state(h).error),
        'El valor supera el saldo del vencimiento.',
      );
    },
  );

  test('error: no toca la lista de movimientos ni invalida nada', () async {
    final h = _harness(
      register: (_) async => throw const NetworkException('Sin conexión.'),
    );
    await h.openViews(detailId: 10);

    await h.container.read(payDueProvider.notifier).pay(_draft());
    final calls = await h.settleViews(detailId: 10);

    expect(calls.dues, 1);
    expect(calls.summary, 1);
    expect(calls.list, 1);
    expect(calls.detail, 1);
    expect(calls.movements, 1);
    expect(h.container.read(movementsProvider).requireValue, isEmpty);
  });

  test(
    'tras un error se puede volver a intentar y esta vez es éxito',
    () async {
      var attempt = 0;
      final h = _harness(
        register: (_) async {
          attempt++;
          if (attempt == 1) throw const NetworkException('Sin conexión.');
          return _paid();
        },
      );
      await h.openViews(detailId: 10);
      final notifier = h.container.read(payDueProvider.notifier);

      await notifier.pay(_draft());
      expect(_state(h).hasError, isTrue);

      await notifier.pay(_draft());
      expect(_state(h).hasError, isFalse);
      expect(h.movements.registerDueCalls, 2);
      expect(h.container.read(movementsProvider).requireValue.single.id, 99);
    },
  );
}
