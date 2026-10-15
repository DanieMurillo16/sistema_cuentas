import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_summary_repository.dart';

void main() {
  test('pide los totales del mes elegido', () async {
    final repository = FakeSummaryRepository((_) async => buildTotals());
    final container = makeContainer(
      overrides: [summaryRepositoryProvider.overrideWithValue(repository)],
    );
    keepAlive(container, [monthSummaryProvider]);

    final summary = await container.read(monthSummaryProvider.future);

    expect(summary.totals.incomeTotalCents, 150000000);
    final now = DateTime.now();
    expect(repository.months.single, DateTime(now.year, now.month));
  });

  test('al cambiar de mes vuelve a pedir y conserva la cifra anterior mientras llega', () async {
    final second = Completer<SummaryTotals>();
    var call = 0;
    final repository = FakeSummaryRepository(
      (_) => ++call == 1
          ? Future.value(buildTotals(netFlowCents: 100))
          : second.future,
    );
    final container = makeContainer(
      overrides: [summaryRepositoryProvider.overrideWithValue(repository)],
    );
    keepAlive(container, [monthSummaryProvider]);
    await container.read(monthSummaryProvider.future);

    container.read(selectedMonthProvider.notifier).previous();
    final state = container.read(monthSummaryProvider);

    expect(state.isLoading, isTrue);
    expect(state.requireValue.totals.netFlowCents, 100);

    second.complete(buildTotals(netFlowCents: 200));
    expect(
      (await container.read(monthSummaryProvider.future)).totals.netFlowCents,
      200,
    );
  });

  test('invalidate (lo que hace una escritura) vuelve a pedir', () async {
    final repository = FakeSummaryRepository((_) async => buildTotals());
    final container = makeContainer(
      overrides: [summaryRepositoryProvider.overrideWithValue(repository)],
    );
    keepAlive(container, [monthSummaryProvider]);
    await container.read(monthSummaryProvider.future);

    container.invalidate(monthSummaryProvider);
    await container.read(monthSummaryProvider.future);

    expect(repository.calls, 2);
  });

  test('error: mensaje en español', () async {
    final container = makeContainer(
      overrides: [
        summaryRepositoryProvider.overrideWithValue(
          FakeSummaryRepository(
            (_) async => throw const NetworkException('Sin red.'),
          ),
        ),
      ],
    );
    keepAlive(container, [monthSummaryProvider]);
    await expectLater(
      container.read(monthSummaryProvider.future),
      throwsA(isA<NetworkException>()),
    );
    expect(
      userErrorMessage(container.read(monthSummaryProvider).error),
      'Sin red.',
    );
  });
}
