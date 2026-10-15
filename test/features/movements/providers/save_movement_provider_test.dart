import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/save_movement_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../support/container_helpers.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/fake_summary_repository.dart';

MovementDraft _draft() => MovementDraft(
  type: MovementType.expense,
  amountPesos: 25000,
  date: dayOfCurrentMonth(1),
  description: 'Mercado',
  categoryId: 3,
  methodId: 2,
);

class _Harness {
  _Harness({FakeMovementsRepository? movements, FakeSummaryRepository? summary})
    : movements = movements ?? FakeMovementsRepository(),
      summary = summary ?? FakeSummaryRepository((_) async => buildTotals()) {
    container = makeContainer(
      overrides: [
        movementsRepositoryProvider.overrideWithValue(this.movements),
        summaryRepositoryProvider.overrideWithValue(this.summary),
      ],
    );
    // Lo que tendrían abierto las pantallas.
    keepAlive(container, [
      saveMovementProvider,
      movementsProvider,
      monthSummaryProvider,
    ]);
  }

  final FakeMovementsRepository movements;
  final FakeSummaryRepository summary;
  late final ProviderContainer container;

  Future<void> loadViews() async {
    await container.read(movementsProvider.future);
    await container.read(monthSummaryProvider.future);
  }

  AsyncValue<void> get state => container.read(saveMovementProvider);
}

void main() {
  test('estado inicial: reposo, sin cargar ni error', () {
    final h = _Harness();
    expect(h.state.isLoading, isFalse);
    expect(h.state.hasError, isFalse);
  });

  test('éxito: manda el borrador, hace upsert en la lista y vuelve a pedir el resumen', () async {
    final saved = buildMovement(
      id: 99,
      date: dayOfCurrentMonth(1),
      description: 'Mercado',
    );
    final h = _Harness(
      movements: FakeMovementsRepository(onRegister: (_) async => saved),
    );
    await h.loadViews();
    expect(h.summary.calls, 1);

    await h.container.read(saveMovementProvider.notifier).save(_draft());

    expect(h.state.hasError, isFalse);
    expect(h.state.isLoading, isFalse);
    expect(h.movements.drafts.single.amountPesos, 25000);
    expect(h.container.read(movementsProvider).requireValue.map((m) => m.id), [
      99,
    ], reason: 'la lista del mes ya tiene el movimiento');
    // El resumen quedó viejo: se vuelve a pedir (lo hace el servidor).
    await h.container.read(monthSummaryProvider.future);
    expect(h.summary.calls, 2);
    expect(h.movements.listCalls, 1, reason: 'la lista no se recarga entera');
  });

  test(
    'otra vista que observa el mismo provider ve el dato nuevo sin recargar',
    () async {
      final h = _Harness(
        movements: FakeMovementsRepository(
          onRegister: (_) async =>
              buildMovement(id: 5, date: DateTime.now(), description: 'Café'),
        ),
      );
      keepAlive(h.container, [homeEntriesProvider]);
      await h.loadViews();
      expect(h.container.read(homeEntriesProvider), isEmpty);

      await h.container.read(saveMovementProvider.notifier).save(_draft());

      final entries = h.container.read(homeEntriesProvider);
      expect(entries.whereType<MovementRowEntry>().single.movement.id, 5);
      expect((entries.first as DayHeaderEntry).label, 'Hoy');
    },
  );

  test(
    'anti doble envío: un segundo save mientras guarda no llama otra vez',
    () async {
      final completer = Completer<Movement>();
      final h = _Harness(
        movements: FakeMovementsRepository(onRegister: (_) => completer.future),
      );
      await h.loadViews();
      final notifier = h.container.read(saveMovementProvider.notifier);

      final first = notifier.save(_draft());
      expect(h.state.isLoading, isTrue);
      await notifier.save(_draft());
      await notifier.save(_draft());

      expect(h.movements.registerCalls, 1);

      completer.complete(buildMovement(id: 1, date: dayOfCurrentMonth(1)));
      await first;
      expect(h.state.isLoading, isFalse);
      expect(h.movements.registerCalls, 1);
    },
  );

  test('error: queda en AsyncError con el mensaje en español y no toca la lista ni el resumen', () async {
    final h = _Harness(
      movements: FakeMovementsRepository(
        onList: (_, _) async => [
          buildMovement(id: 1, date: dayOfCurrentMonth(1)),
        ],
        onRegister: (_) async => throw const ApiException(
          'La fecha no puede ser futura.',
          code: 'FECHA_FUTURA',
          statusCode: 422,
        ),
      ),
    );
    await h.loadViews();

    await h.container.read(saveMovementProvider.notifier).save(_draft());

    expect(h.state.hasError, isTrue);
    expect(userErrorMessage(h.state.error), 'La fecha no puede ser futura.');
    expect(h.container.read(movementsProvider).requireValue.map((m) => m.id), [
      1,
    ]);
    await h.container.read(monthSummaryProvider.future);
    expect(h.summary.calls, 1, reason: 'no se invalida si falló');
  });

  test('tras un error se puede volver a guardar', () async {
    var attempt = 0;
    final h = _Harness(
      movements: FakeMovementsRepository(
        onRegister: (_) async {
          attempt++;
          if (attempt == 1) throw const NetworkException('Sin conexión.');
          return buildMovement(id: 7, date: dayOfCurrentMonth(1));
        },
      ),
    );
    await h.loadViews();
    final notifier = h.container.read(saveMovementProvider.notifier);

    await notifier.save(_draft());
    expect(h.state.hasError, isTrue);

    await notifier.save(_draft());
    expect(h.state.hasError, isFalse);
    expect(h.container.read(movementsProvider).requireValue.single.id, 7);
    expect(h.movements.registerCalls, 2);
  });

  test('un movimiento de otro mes se guarda pero no aparece en la lista del mes mostrado', () async {
    final now = DateTime.now();
    final h = _Harness(
      movements: FakeMovementsRepository(
        onRegister: (_) async =>
            buildMovement(id: 3, date: DateTime(now.year, now.month - 1, 15)),
      ),
    );
    await h.loadViews();

    await h.container.read(saveMovementProvider.notifier).save(_draft());

    expect(h.state.hasError, isFalse);
    expect(h.container.read(movementsProvider).requireValue, isEmpty);
  });
}
