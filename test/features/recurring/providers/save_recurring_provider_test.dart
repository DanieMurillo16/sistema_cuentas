import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/save_recurring_provider.dart';

import '../../../helpers/recurring_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_recurring_repository.dart';
import '../../../support/recurring_harness.dart';

RecurringDraft _draft() => RecurringDraft(
  type: MovementType.income,
  description: 'Arriendo de Oscar',
  valuePesos: 180000,
  dayOfMonth: 7,
  everyMonths: 1,
  startDate: DateTime(2026, 10, 1),
  categoryId: 9,
);

RecurringHarness _harness({
  Future<RecurringPayment> Function(RecurringDraft draft)? create,
}) {
  final h = RecurringHarness(
    recurring: FakeRecurringRepository(
      onList: () async => [buildRecurring(id: 1, day: 20)],
      onCreate: create ?? (_) async => buildRecurring(id: 55, day: 7),
    ),
  );
  keepAlive(h.container, [saveRecurringProvider]);
  return h;
}

AsyncValue<void> _state(RecurringHarness h) =>
    h.container.read(saveRecurringProvider);

void main() {
  test('estado inicial: en reposo', () {
    final h = _harness();
    expect(_state(h).isLoading, isFalse);
    expect(_state(h).hasError, isFalse);
  });

  test(
    'éxito: manda el borrador y hace upsert en la lista compartida',
    () async {
      final h = _harness();
      await h.openViews();

      await h.container.read(saveRecurringProvider.notifier).save(_draft());

      expect(_state(h).hasError, isFalse);
      expect(h.recurring.created.single.description, 'Arriendo de Oscar');
      expect(
        h.container.read(recurringListProvider).requireValue.map((p) => p.id),
        [55, 1],
        reason: 'ordenada por día de pago: el 7 antes que el 20',
      );
      expect(h.recurring.listCalls, 1, reason: 'upsert, sin recargar la lista');
    },
  );

  test(
    'éxito: vuelve a pedir los vencimientos (el servidor generó los del mes)',
    () async {
      final h = _harness();
      await h.openViews();
      expect(h.dues.calls, 1);

      await h.container.read(saveRecurringProvider.notifier).save(_draft());
      await h.container.read(duesProvider.future);

      expect(h.dues.calls, 2);
    },
  );

  test(
    'éxito: otra vista que observa la lista ve el acuerdo sin recargar',
    () async {
      final h = _harness();
      await h.openViews();
      keepAlive(h.container, [visibleRecurringProvider]);

      await h.container.read(saveRecurringProvider.notifier).save(_draft());

      expect(
        h.container
            .read(visibleRecurringProvider)
            .requireValue
            .map((p) => p.id),
        contains(55),
      );
    },
  );

  test(
    'anti doble envío: un segundo save mientras guarda no llama otra vez',
    () async {
      final completer = Completer<RecurringPayment>();
      final h = _harness(create: (_) => completer.future);
      await h.openViews();
      final notifier = h.container.read(saveRecurringProvider.notifier);

      final first = notifier.save(_draft());
      expect(_state(h).isLoading, isTrue);
      await notifier.save(_draft());
      await notifier.save(_draft());
      expect(h.recurring.createCalls, 1);

      completer.complete(buildRecurring(id: 55));
      await first;
      expect(_state(h).isLoading, isFalse);
      expect(h.recurring.createCalls, 1);
    },
  );

  test(
    'error: AsyncError con el mensaje; la lista y los vencimientos no cambian',
    () async {
      final h = _harness(
        create: (_) async => throw const ApiException(
          'La categoría no puede ser de capital.',
          code: 'CATEGORIA_INVALIDA',
          statusCode: 422,
        ),
      );
      await h.openViews();

      await h.container.read(saveRecurringProvider.notifier).save(_draft());
      final calls = await h.settleViews();

      // Riverpod 3: un AsyncError puede conservar el valor anterior; el éxito
      // nunca se decide con hasValue.
      expect(_state(h).hasError, isTrue);
      expect(_state(h).isLoading, isFalse);
      expect(
        userErrorMessage(_state(h).error),
        'La categoría no puede ser de capital.',
      );
      expect(
        h.container.read(recurringListProvider).requireValue.map((p) => p.id),
        [1],
      );
      expect(calls.dues, 1);
      expect(calls.list, 1);
    },
  );

  test('tras un error se puede reintentar', () async {
    var attempt = 0;
    final h = _harness(
      create: (_) async {
        attempt++;
        if (attempt == 1) throw const NetworkException('Sin conexión.');
        return buildRecurring(id: 55);
      },
    );
    await h.openViews();
    final notifier = h.container.read(saveRecurringProvider.notifier);

    await notifier.save(_draft());
    expect(_state(h).hasError, isTrue);

    await notifier.save(_draft());
    expect(_state(h).hasError, isFalse);
    expect(h.recurring.createCalls, 2);
  });

  test(
    'si se cierra la pantalla mientras guarda, la escritura termina igual',
    () async {
      final completer = Completer<RecurringPayment>();
      final h = RecurringHarness(
        recurring: FakeRecurringRepository(
          onList: () async => [buildRecurring(id: 1)],
          onCreate: (_) => completer.future,
        ),
      );
      await h.openViews();

      // Nadie observa saveRecurringProvider (la pantalla ya se cerró).
      final saving = h.container
          .read(saveRecurringProvider.notifier)
          .save(_draft());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      completer.complete(buildRecurring(id: 55));
      await saving;

      expect(
        h.container.read(recurringListProvider).requireValue.map((p) => p.id),
        containsAll([1, 55]),
      );
    },
  );
}
