import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';

import '../../helpers/movement_fixtures.dart';
import '../../helpers/summary_fixtures.dart';
import '../../support/container_helpers.dart';
import '../../support/fake_summary_repository.dart';

/// Un resumen cuyo ingreso codifica el mes (año × 100 + mes) para saber de qué
/// mes salió cada punto.
MonthSummary _summaryOf(DateTime month) => buildMonthSummary(
  totals: buildTotals(incomeCents: month.year * 100 + month.month),
);

int _codeOf(MonthSummary summary) => summary.totals.incomeTotalCents;

DateTime get _thisMonth {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

/// [views] deja vivas (como haría la pantalla) las gráficas del resumen; sin
/// ellas, solo se pide lo que la prueba lea.
ProviderContainer _container(FakeSummaryRepository repo, {bool views = true}) {
  final container = makeContainer(
    overrides: [summaryRepositoryProvider.overrideWithValue(repo)],
  );
  if (views) {
    keepAlive(container, [
      monthSummaryProvider,
      monthlyTrendProvider,
      previousMonthSummaryProvider,
    ]);
  }
  return container;
}

FakeSummaryRepository _repo({
  Future<MonthSummary> Function(DateTime month)? onMonth,
}) => FakeSummaryRepository(
  (_) async => throw StateError('no se usa'),
  onMonth: onMonth ?? (m) async => _summaryOf(m),
);

void main() {
  group('monthlyTrendProvider', () {
    test('devuelve $trendMonths puntos, del más viejo al elegido', () async {
      final container = _container(_repo());

      final points = await container.read(monthlyTrendProvider.future);

      expect(points, hasLength(trendMonths));
      expect(
        [for (final p in points) p.month],
        [
          for (var back = trendMonths - 1; back >= 0; back--)
            monthsBefore(_thisMonth, back),
        ],
      );
      expect(points.last.month, _thisMonth, reason: 'el elegido va al final');
      for (final p in points) {
        expect(
          _codeOf(p.summary),
          p.month.year * 100 + p.month.month,
          reason: 'el resumen de ${p.month} es de ese mes',
        );
      }
    });

    test('pide cada mes una sola vez (5 anteriores + el elegido)', () async {
      final repo = _repo();
      final container = _container(repo);

      await container.read(monthlyTrendProvider.future);

      expect(repo.calls, trendMonths);
      expect(repo.months.toSet(), hasLength(trendMonths));
    });

    test(
      'el mes elegido sale de monthSummaryProvider (se actualiza con él)',
      () async {
        var current = 1;
        final repo = _repo(
          onMonth: (m) async => m == _thisMonth
              ? buildMonthSummary(
                  totals: buildTotals(incomeCents: 7000 + current),
                )
              : _summaryOf(m),
        );
        final container = _container(repo);
        expect(
          (await container.read(monthlyTrendProvider.future))
              .last
              .summary
              .totals
              .incomeTotalCents,
          7001,
        );

        current = 2; // una escritura lo invalida
        container.invalidate(monthSummaryProvider);
        final points = await container.read(monthlyTrendProvider.future);

        expect(points.last.summary.totals.incomeTotalCents, 7002);
        // Los meses anteriores no se volvieron a pedir.
        expect(
          repo.months.where((m) => m != _thisMonth).toSet().length,
          trendMonths - 1,
        );
        expect(
          repo.months.where((m) => m != _thisMonth),
          hasLength(trendMonths - 1),
        );
      },
    );

    test(
      'al retroceder un mes reutiliza lo ya pedido (solo pide lo nuevo)',
      () async {
        final repo = _repo();
        final container = _container(repo);
        await container.read(monthlyTrendProvider.future);
        expect(repo.calls, 6);

        container.read(selectedMonthProvider.notifier).previous();
        final points = await container.read(monthlyTrendProvider.future);

        final previous = monthsBefore(_thisMonth, 1);
        expect(points.last.month, previous);
        expect(points.first.month, monthsBefore(previous, trendMonths - 1));
        // Nuevo: el mes elegido (monthSummary) y el más viejo de la serie.
        expect(repo.calls, 8);
      },
    );

    test('un mes anterior que falla: la serie queda en error', () async {
      final repo = _repo(
        onMonth: (m) async {
          if (m == monthsBefore(_thisMonth, 2)) {
            throw const NetworkException('Sin conexión con el servidor.');
          }
          return _summaryOf(m);
        },
      );
      final container = _container(repo);

      await expectLater(
        container.read(monthlyTrendProvider.future),
        throwsA(isA<NetworkException>()),
      );
      expect(
        userErrorMessage(container.read(monthlyTrendProvider).error),
        'Sin conexión con el servidor.',
      );
      // El resumen del mes elegido NO depende de las gráficas.
      expect(container.read(monthSummaryProvider).hasError, isFalse);
    });

    test('tras un fallo, invalidar SOLO la serie no basta: el mes que falló '
        'queda en error en su propio provider (hay que invalidar summaryForMonth)', () async {
      var fail = true;
      final bad = monthsBefore(_thisMonth, 3);
      final container = _container(
        _repo(
          onMonth: (m) async {
            if (fail && m == bad) {
              throw const NetworkException('Sin conexión con el servidor.');
            }
            return _summaryOf(m);
          },
        ),
      );
      await expectLater(
        container.read(monthlyTrendProvider.future),
        throwsA(isA<NetworkException>()),
      );
      fail = false;

      container.invalidate(monthlyTrendProvider);
      await expectLater(
        container.read(monthlyTrendProvider.future),
        throwsA(isA<NetworkException>()),
        reason: 'el error de ese mes sigue guardado',
      );

      container.invalidate(summaryForMonthProvider);
      expect(
        await container.read(monthlyTrendProvider.future),
        hasLength(trendMonths),
      );
    });

    test('mientras llega: cargando, sin valor', () {
      final never = Completer<MonthSummary>();
      final container = _container(_repo(onMonth: (_) => never.future));
      final state = container.read(monthlyTrendProvider);
      expect(state.isLoading, isTrue);
      expect(state.hasValue, isFalse);
    });
  });

  group('summaryForMonthProvider', () {
    test('pide por mes y reutiliza lo ya pedido', () async {
      final repo = _repo();
      final container = _container(repo, views: false);
      final march = DateTime(2026, 3);
      final april = DateTime(2026, 4);
      keepAlive(container, [
        summaryForMonthProvider(march),
        summaryForMonthProvider(april),
      ]);

      final a = await container.read(summaryForMonthProvider(march).future);
      final b = await container.read(summaryForMonthProvider(april).future);
      final again = await container.read(summaryForMonthProvider(march).future);

      expect(_codeOf(a), 202603);
      expect(_codeOf(b), 202604);
      expect(_codeOf(again), 202603);
      expect(repo.months, [march, april]);
    });

    test(
      'la familia se identifica por el mes (mismo mes = misma clave)',
      () async {
        final repo = _repo();
        final container = _container(repo, views: false);
        keepAlive(container, [summaryForMonthProvider(DateTime(2026, 3))]);

        await container.read(summaryForMonthProvider(DateTime(2026, 3)).future);
        await container.read(summaryForMonthProvider(DateTime(2026, 3)).future);

        expect(repo.calls, 1);
      },
    );
  });

  group('previousMonthSummaryProvider', () {
    test('es el resumen del mes anterior al elegido', () async {
      final container = _container(_repo());

      final previous = await container.read(
        previousMonthSummaryProvider.future,
      );

      final expected = monthsBefore(_thisMonth, 1);
      expect(_codeOf(previous), expected.year * 100 + expected.month);
    });

    test('sigue al mes elegido y comparte lo ya pedido con la serie', () async {
      final repo = _repo();
      final container = _container(repo);
      await container.read(
        monthlyTrendProvider.future,
      ); // pide 5 anteriores + actual
      final before = repo.calls;

      await container.read(previousMonthSummaryProvider.future);
      expect(repo.calls, before, reason: 'ya estaba en summaryForMonth');

      container.read(selectedMonthProvider.notifier).previous();
      final shifted = await container.read(previousMonthSummaryProvider.future);
      final two = monthsBefore(_thisMonth, 2);
      expect(_codeOf(shifted), two.year * 100 + two.month);
    });

    test('error del mes anterior: se propaga como error', () async {
      final container = _container(
        _repo(
          onMonth: (m) async => m == monthsBefore(_thisMonth, 1)
              ? throw const NetworkException('Sin red.')
              : _summaryOf(m),
        ),
      );
      await expectLater(
        container.read(previousMonthSummaryProvider.future),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
