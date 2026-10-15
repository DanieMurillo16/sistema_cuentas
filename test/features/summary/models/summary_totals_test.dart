import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

import '../../../helpers/movement_fixtures.dart';

void main() {
  test('mapea los totales del servidor a centavos sin recalcular nada', () {
    final t = SummaryTotals.fromJson(
      summaryTotalsJson(
        income: '1500000.00',
        expense: '420000.50',
        netFlow: '1079999.50',
        count: 12,
      ),
    );
    expect(t.incomeTotalCents, 150000000);
    expect(t.expenseTotalCents, 42000050);
    expect(t.netFlowCents, 107999950);
    expect(t.operatingBalanceCents, 107999950);
    expect(t.capitalRecoveredCents, 0);
    expect(t.capitalDeliveredCents, 0);
    expect(t.movementCount, 12);
  });

  test('flujo neto negativo', () {
    final t = SummaryTotals.fromJson(summaryTotalsJson(netFlow: '-3.10'));
    expect(t.netFlowCents, -310);
  });

  test('un campo faltante: error propio en español, no un TypeError', () {
    for (final key in [
      'ingresos_total',
      'gastos_total',
      'flujo_neto',
      'balance_operativo',
      'capital_recuperado',
      'capital_entregado',
      'movimientos',
    ]) {
      final json = summaryTotalsJson()..remove(key);
      expect(
        () => parseApi(() => SummaryTotals.fromJson(json)),
        throwsA(
          isA<UnexpectedException>().having(
            (e) => e.message,
            'message',
            startsWith('El servidor devolvió datos'),
          ),
        ),
        reason: 'falta $key',
      );
    }
  });

  test('un importe con formato inválido: error propio', () {
    expect(
      () => parseApi(
        () => SummaryTotals.fromJson(summaryTotalsJson(income: 'mucho')),
      ),
      throwsA(isA<UnexpectedException>()),
    );
  });
}
