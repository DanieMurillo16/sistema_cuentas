import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/network/api_response.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/summary_dues.dart';

import '../../../helpers/summary_fixtures.dart';

/// Debe lanzar el error propio en español, no un `TypeError`.
Matcher get _incompleteData => throwsA(
  isA<UnexpectedException>().having(
    (e) => e.message,
    'message',
    startsWith('El servidor devolvió datos'),
  ),
);

void main() {
  group('CategoryTotal.fromJson', () {
    test('mapea todos los campos y el dinero a centavos', () {
      final c = CategoryTotal.fromJson(
        categoryTotalJson(
          type: 'INGRESO',
          id: 9,
          name: 'Salario',
          isCapital: true,
          total: '1500000.50',
          count: 3,
        ),
      );
      expect(c.type, MovementType.income);
      expect(c.categoryId, 9);
      expect(c.name, 'Salario');
      expect(c.isCapital, isTrue);
      expect(c.totalCents, 150000050);
      expect(c.count, 3);
    });

    test('es_capital ausente es falso y el nombre ausente queda vacío', () {
      final json = categoryTotalJson()
        ..remove('es_capital')
        ..remove('categoria');
      final c = CategoryTotal.fromJson(json);
      expect(c.isCapital, isFalse);
      expect(c.name, '');
    });

    test('campos obligatorios faltantes: error propio en español', () {
      for (final key in ['tipo', 'id_categoria', 'total', 'cantidad']) {
        final json = categoryTotalJson()..remove(key);
        expect(
          () => parseApi(() => CategoryTotal.fromJson(json)),
          _incompleteData,
          reason: 'falta $key',
        );
      }
    });

    test('un tipo desconocido o un total inválido: error propio', () {
      expect(
        () => parseApi(
          () => CategoryTotal.fromJson(categoryTotalJson(type: 'OTRO')),
        ),
        _incompleteData,
      );
      expect(
        () => parseApi(
          () => CategoryTotal.fromJson(categoryTotalJson(total: 'mucho')),
        ),
        _incompleteData,
      );
    });
  });

  group('MethodTotal.fromJson', () {
    test('mapea todos los campos', () {
      final m = MethodTotal.fromJson(
        methodTotalJson(
          type: 'INGRESO',
          id: 5,
          name: 'Bancolombia',
          total: '10.00',
          count: 4,
        ),
      );
      expect(m.type, MovementType.income);
      expect(m.methodId, 5);
      expect(m.name, 'Bancolombia');
      expect(m.totalCents, 1000);
      expect(m.count, 4);
    });

    test('campos obligatorios faltantes: error propio en español', () {
      for (final key in ['tipo', 'id_medio', 'total', 'cantidad']) {
        final json = methodTotalJson()..remove(key);
        expect(
          () => parseApi(() => MethodTotal.fromJson(json)),
          _incompleteData,
          reason: 'falta $key',
        );
      }
    });
  });

  group('SummaryDues.fromJson', () {
    test('mapea el saldo, lo vencido y las cantidades', () {
      final d = SummaryDues.fromJson(
        summaryDuesJson(
          type: 'GASTO',
          balance: '90000.00',
          overdueBalance: '30000.00',
          pending: 4,
          overdue: 2,
        ),
      );
      expect(d.type, MovementType.expense);
      expect(d.balanceCents, 9000000);
      expect(d.overdueBalanceCents, 3000000);
      expect(d.pendingCount, 4);
      expect(d.overdueCount, 2);
    });

    test('campos obligatorios faltantes: error propio en español', () {
      for (final key in [
        'tipo',
        'saldo',
        'saldo_vencido',
        'cantidad_pendiente',
        'cantidad_vencida',
      ]) {
        final json = summaryDuesJson()..remove(key);
        expect(
          () => parseApi(() => SummaryDues.fromJson(json)),
          _incompleteData,
          reason: 'falta $key',
        );
      }
    });
  });

  group('MonthSummary.duesFor', () {
    test('devuelve la fila del tipo pedido', () {
      final summary = buildMonthSummary();
      expect(summary.duesFor(MovementType.income).balanceCents, 18000000);
      expect(summary.duesFor(MovementType.expense).overdueCount, 1);
    });

    test('sin filas de ese tipo: ceros, nunca un error', () {
      final summary = buildMonthSummary(dues: const []);
      final income = summary.duesFor(MovementType.income);
      expect(income.type, MovementType.income);
      expect(income.balanceCents, 0);
      expect(income.overdueBalanceCents, 0);
      expect(income.pendingCount, 0);
      expect(income.overdueCount, 0);
    });

    test('con solo una fila, el otro tipo queda en cero', () {
      final summary = buildMonthSummary(dues: [buildSummaryDues()]);
      expect(summary.duesFor(MovementType.expense).balanceCents, 0);
    });
  });
}
