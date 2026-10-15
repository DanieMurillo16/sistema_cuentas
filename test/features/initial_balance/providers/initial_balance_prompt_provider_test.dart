import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/initial_balance/providers/initial_balance_prompt_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/summary_fixtures.dart';
import '../../../support/fake_movements_repository.dart';
import '../../../support/fake_summary_repository.dart';
import '../../../support/session_overrides.dart';

MonthSummary get _emptyMonth => buildMonthSummary(
  totals: buildTotals(
    incomeCents: 0,
    expenseCents: 0,
    netFlowCents: 0,
    count: 0,
  ),
  byCategory: const [],
  byMethod: const [],
  dues: const [],
);

class _Rig {
  _Rig({
    Set<String> permissions = const {Permissions.registerMovements},
    Future<List<Movement>> Function()? movements,
    Future<MonthSummary> Function()? previous,
  }) {
    final session = sessionOverrides(permissions: permissions);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...session.overrides,
        movementsRepositoryProvider.overrideWithValue(
          FakeMovementsRepository(
            onList: (_, _) => (movements ?? () async => const [])(),
          ),
        ),
        summaryRepositoryProvider.overrideWithValue(
          FakeSummaryRepository(
            (_) async => throw StateError('no se usa'),
            onMonth: (_) => (previous ?? () async => _emptyMonth)(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(showInitialBalancePromptProvider, (_, _) {});
  }

  late final ProviderContainer container;

  bool get show => container.read(showInitialBalancePromptProvider);

  /// Espera a que lleguen la sesión, los movimientos y el mes anterior.
  Future<void> settle() async {
    await container.read(sessionProvider.future);
    await container
        .read(movementsProvider.future)
        .then((_) {}, onError: (_) {});
    await container
        .read(previousMonthSummaryProvider.future)
        .then((_) {}, onError: (_) {});
  }
}

void main() {
  group('las cinco condiciones', () {
    test('todo cumplido: se invita', () async {
      final r = _Rig();
      await r.settle();
      expect(r.show, isTrue);
    });

    test('1. sin permiso para registrar movimientos: no', () async {
      final r = _Rig(permissions: const {Permissions.manageCatalogs});
      await r.settle();
      expect(r.show, isFalse);
    });

    test('2. viendo otro mes (no el actual): no', () async {
      final r = _Rig();
      await r.settle();
      expect(r.show, isTrue);

      r.container.read(selectedMonthProvider.notifier).previous();
      await r.settle();

      expect(r.show, isFalse);
    });

    test('2b. el mes siguiente tampoco', () async {
      final r = _Rig();
      await r.settle();

      r.container.read(selectedMonthProvider.notifier).next();
      await r.settle();

      expect(r.show, isFalse);
    });

    test('3. el mes actual ya tiene movimientos: no', () async {
      final r = _Rig(
        movements: () async => [buildMovement(date: dayOfCurrentMonth(1))],
      );
      await r.settle();
      expect(r.show, isFalse);
    });

    test('4. el mes anterior tuvo movimientos: no (ya usa la app)', () async {
      final r = _Rig(previous: () async => buildMonthSummary());
      await r.settle();
      expect(r.show, isFalse);
    });

    test(
      '4b. el mes anterior solo tuvo vencimientos pendientes: tampoco',
      () async {
        final r = _Rig(
          previous: () async => buildMonthSummary(
            totals: buildTotals(
              incomeCents: 0,
              expenseCents: 0,
              netFlowCents: 0,
              count: 0,
            ),
            dues: [buildSummaryDues(pendingCount: 2)],
          ),
        );
        await r.settle();
        expect(r.show, isFalse);
      },
    );
  });

  group('mientras carga o si falla, no molesta', () {
    test('movimientos cargando: no', () async {
      final gate = Completer<List<Movement>>();
      final r = _Rig(movements: () => gate.future);
      await r.container.read(sessionProvider.future);
      await r.container.read(previousMonthSummaryProvider.future);

      expect(r.show, isFalse);

      gate.complete(const []);
      await r.container.read(movementsProvider.future);
      expect(r.show, isTrue);
    });

    test('mes anterior cargando: no', () async {
      final gate = Completer<MonthSummary>();
      final r = _Rig(previous: () => gate.future);
      await r.container.read(sessionProvider.future);
      await r.container.read(movementsProvider.future);

      expect(r.show, isFalse);

      gate.complete(_emptyMonth);
      await r.container.read(previousMonthSummaryProvider.future);
      expect(r.show, isTrue);
    });

    test('error al cargar movimientos: no', () async {
      final r = _Rig(
        movements: () async => throw const NetworkException('Sin conexión.'),
      );
      await r.settle();
      expect(r.show, isFalse);
    });

    test('error al cargar el mes anterior: no', () async {
      final r = _Rig(
        previous: () async => throw const NetworkException('Sin conexión.'),
      );
      await r.settle();
      expect(r.show, isFalse);
    });
  });

  test('al registrar el primer movimiento la invitación desaparece', () async {
    final r = _Rig();
    await r.settle();
    expect(r.show, isTrue);

    r.container
        .read(movementsProvider.notifier)
        .upsert(buildMovement(id: 1, date: dayOfCurrentMonth(1)));

    expect(r.show, isFalse);
  });
}
