import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_endpoints.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/summary_fixtures.dart';
import '../../../support/api_harness.dart';
import '../../../support/fake_api_adapter.dart';

SummaryRepository _repo(ApiHarness h) => SummaryRepository(h.api);

/// Sin «totales» llega «incompletos»; con un campo mal formado, «no válidos».
Matcher get _incomplete => throwsA(
  isA<UnexpectedException>().having(
    (e) => e.message,
    'message',
    startsWith('El servidor devolvió datos'),
  ),
);

void main() {
  test('pide el periodo AAAA-MM a resumen/mes.php con el token', () async {
    final h = ApiHarness(
      FakeApiAdapter.json(successEnvelope(monthSummaryJson())),
    );

    await _repo(h).month(DateTime(2026, 3, 15));

    expect(h.single.method, 'GET');
    expect(h.single.path, ApiEndpoints.summaryMonth);
    expect(h.single.options.queryParameters, {'periodo': '2026-03'});
    expect(h.single.authorization, 'Bearer tok');
  });

  test(
    'arma el resumen completo: totales, categorías, medios y vencimientos',
    () async {
      final h = ApiHarness(
        FakeApiAdapter.json(
          successEnvelope(
            monthSummaryJson(totals: summaryTotalsJson(income: '2000000.00')),
          ),
        ),
      );

      final summary = await _repo(h).month(DateTime(2026, 10));

      expect(summary.totals.incomeTotalCents, 200000000);
      expect(summary.totals.movementCount, 12);

      expect(summary.byCategory, hasLength(2));
      expect(summary.byCategory.first.name, 'Salario');
      expect(summary.byCategory.first.type, MovementType.income);
      expect(summary.byCategory.last.totalCents, 42000000);

      expect(summary.byMethod, hasLength(2));
      expect(summary.byMethod.last.name, 'Nequi');
      expect(summary.byMethod.last.totalCents, 42000050);

      expect(summary.dues, hasLength(2));
      final expense = summary.duesFor(MovementType.expense);
      expect(expense.balanceCents, 9000000);
      expect(expense.overdueBalanceCents, 3000000);
      expect(expense.overdueCount, 1);
    },
  );

  test('sin las listas del desglose: quedan vacías, no revienta', () async {
    final h = ApiHarness(
      FakeApiAdapter.json(successEnvelope({'totales': summaryTotalsJson()})),
    );

    final summary = await _repo(h).month(DateTime(2026, 10));

    expect(summary.byCategory, isEmpty);
    expect(summary.byMethod, isEmpty);
    expect(summary.dues, isEmpty);
    expect(summary.duesFor(MovementType.income).balanceCents, 0);
  });

  test('sin «totales»: error propio en español', () async {
    final h = ApiHarness(FakeApiAdapter.json(successEnvelope({'x': 1})));
    await expectLater(_repo(h).month(DateTime(2026, 10)), _incomplete);
  });

  test(
    'un campo faltante en totales, categorías, medios o vencimientos',
    () async {
      final broken = <String, Map<String, dynamic>>{
        'totales': monthSummaryJson(
          totals: summaryTotalsJson()..remove('flujo_neto'),
        ),
        'categoría': monthSummaryJson(
          byCategory: [categoryTotalJson()..remove('total')],
        ),
        'medio': monthSummaryJson(
          byMethod: [methodTotalJson()..remove('id_medio')],
        ),
        'vencimiento': monthSummaryJson(
          dues: [summaryDuesJson()..remove('saldo_vencido')],
        ),
      };
      for (final entry in broken.entries) {
        final h = ApiHarness(FakeApiAdapter.json(successEnvelope(entry.value)));
        await expectLater(
          _repo(h).month(DateTime(2026, 10)),
          _incomplete,
          reason: 'falla ${entry.key}',
        );
      }
    },
  );

  test('error del servidor y sin conexión llegan en español', () async {
    final server = ApiHarness(
      FakeApiAdapter.json(
        errorEnvelope('PERIODO_INVALIDO', 'El periodo no es válido.'),
        status: 422,
      ),
    );
    await expectLater(
      _repo(server).month(DateTime(2030)),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'El periodo no es válido.',
        ),
      ),
    );

    final offline = ApiHarness(FakeApiAdapter.connectionError());
    await expectLater(
      _repo(offline).month(DateTime(2026, 10)),
      throwsA(isA<NetworkException>()),
    );
  });

  test('un 401 con token cierra la sesión local', () async {
    final h = ApiHarness(
      FakeApiAdapter.json(
        errorEnvelope('NO_AUTENTICADO', 'Sesión vencida.'),
        status: 401,
      ),
    );
    await expectLater(
      _repo(h).month(DateTime(2026, 10)),
      throwsA(isA<ApiException>()),
    );
    expect(h.unauthorizedCalls, 1);
  });
}
