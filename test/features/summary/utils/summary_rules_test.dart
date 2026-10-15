import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/summary/models/monthly_point.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/summary_fixtures.dart';

void main() {
  group('SummaryRules.methodFlows', () {
    test('sin filas: lista vacía', () {
      expect(SummaryRules.methodFlows(const []), isEmpty);
    });

    test('une ingreso y gasto del mismo medio en una sola fila', () {
      final flows = SummaryRules.methodFlows([
        buildMethodTotal(type: MovementType.income, id: 2, totalCents: 100000),
        buildMethodTotal(id: 2, totalCents: 30000),
      ]);

      expect(flows, hasLength(1));
      expect(flows.single.methodId, 2);
      expect(flows.single.incomeCents, 100000);
      expect(flows.single.expenseCents, 30000);
      expect(flows.single.netCents, 70000);
    });

    test(
      'un medio solo con gastos queda en negativo; solo ingresos, positivo',
      () {
        final flows = SummaryRules.methodFlows([
          buildMethodTotal(id: 1, name: 'Efectivo', totalCents: 5000),
          buildMethodTotal(
            type: MovementType.income,
            id: 2,
            name: 'Nequi',
            totalCents: 8000,
          ),
        ]);

        final cash = flows.firstWhere((f) => f.methodId == 1);
        final nequi = flows.firstWhere((f) => f.methodId == 2);
        expect(cash.incomeCents, 0);
        expect(cash.netCents, -5000);
        expect(nequi.expenseCents, 0);
        expect(nequi.netCents, 8000);
      },
    );

    test('ordena por neto de mayor a menor', () {
      final flows = SummaryRules.methodFlows([
        buildMethodTotal(id: 1, name: 'A', totalCents: 5000), // -5000
        buildMethodTotal(
          type: MovementType.income,
          id: 2,
          name: 'B',
          totalCents: 9000, // +9000
        ),
        buildMethodTotal(
          type: MovementType.income,
          id: 3,
          name: 'C',
          totalCents: 2000, // +2000
        ),
      ]);

      expect([for (final f in flows) f.name], ['B', 'C', 'A']);
    });

    test('con el mismo neto desempata por nombre', () {
      final flows = SummaryRules.methodFlows([
        buildMethodTotal(
          type: MovementType.income,
          id: 1,
          name: 'Zeta',
          totalCents: 1000,
        ),
        buildMethodTotal(
          type: MovementType.income,
          id: 2,
          name: 'Alfa',
          totalCents: 1000,
        ),
      ]);

      expect([for (final f in flows) f.name], ['Alfa', 'Zeta']);
    });

    test('no altera la lista de entrada', () {
      final rows = [
        buildMethodTotal(id: 1, totalCents: 5000),
        buildMethodTotal(type: MovementType.income, id: 2, totalCents: 9000),
      ];
      SummaryRules.methodFlows(rows);
      expect(rows.first.methodId, 1);
    });
  });

  group('SummaryRules.categoryShares', () {
    test('sin filas del tipo: lista vacía', () {
      expect(
        SummaryRules.categoryShares(const [], MovementType.expense),
        isEmpty,
      );
      expect(
        SummaryRules.categoryShares([
          buildCategoryTotal(type: MovementType.income),
        ], MovementType.expense),
        isEmpty,
      );
    });

    test('filtra por tipo, excluye capital y ordena de mayor a menor', () {
      final shares = SummaryRules.categoryShares([
        buildCategoryTotal(id: 1, name: 'Mercado', totalCents: 2000),
        buildCategoryTotal(id: 2, name: 'Arriendo', totalCents: 6000),
        buildCategoryTotal(
          id: 3,
          name: 'Préstamo',
          totalCents: 99999,
          isCapital: true,
        ),
        buildCategoryTotal(
          type: MovementType.income,
          id: 4,
          name: 'Salario',
          totalCents: 50000,
        ),
      ], MovementType.expense);

      expect([for (final s in shares) s.name], ['Arriendo', 'Mercado']);
    });

    test('share es la parte del total del grupo y suma 1', () {
      final shares = SummaryRules.categoryShares([
        buildCategoryTotal(id: 1, totalCents: 2500),
        buildCategoryTotal(id: 2, name: 'Otra', totalCents: 7500),
      ], MovementType.expense);

      expect(shares[0].share, closeTo(0.75, 1e-9));
      expect(shares[1].share, closeTo(0.25, 1e-9));
      expect(
        shares.fold<double>(0, (sum, s) => sum + s.share),
        closeTo(1, 1e-9),
      );
    });

    test('conserva el id de cada categoría (para abrir sus movimientos)', () {
      final shares = SummaryRules.categoryShares([
        buildCategoryTotal(id: 7, name: 'Mercado', totalCents: 100),
      ], MovementType.expense);
      expect(shares.single.categoryId, 7);
    });

    test('una sola categoría ocupa todo (share 1) y conserva la cantidad', () {
      final shares = SummaryRules.categoryShares([
        buildCategoryTotal(totalCents: 1234, count: 7),
      ], MovementType.expense);

      expect(shares.single.share, 1);
      expect(shares.single.count, 7);
      expect(shares.single.totalCents, 1234);
    });

    test('total en cero no divide entre cero: share 0', () {
      final shares = SummaryRules.categoryShares([
        buildCategoryTotal(id: 1, totalCents: 0),
        buildCategoryTotal(id: 2, name: 'Otra', totalCents: 0),
      ], MovementType.expense);

      expect(shares.map((s) => s.share), everyElement(0));
    });

    test('solo hay capital en ese tipo: queda vacío', () {
      expect(
        SummaryRules.categoryShares([
          buildCategoryTotal(isCapital: true),
        ], MovementType.expense),
        isEmpty,
      );
    });
  });

  group('SummaryRules.groupTotal', () {
    test('suma las categorías del grupo (0 si no hay)', () {
      expect(SummaryRules.groupTotal(const []), 0);
      final shares = SummaryRules.categoryShares([
        buildCategoryTotal(id: 1, totalCents: 2500),
        buildCategoryTotal(id: 2, name: 'Otra', totalCents: 7500),
      ], MovementType.expense);
      expect(SummaryRules.groupTotal(shares), 10000);
    });
  });

  group('SummaryRules.topCategories', () {
    List<CategoryShare> sharesOf(int n) => SummaryRules.categoryShares([
      for (var i = 1; i <= n; i++)
        buildCategoryTotal(
          id: i,
          name: 'Cat $i',
          totalCents: i * 1000,
          count: i,
        ),
    ], MovementType.expense);

    test('con 6 o menos queda intacta (misma lista)', () {
      for (final n in [0, 1, 5, 6]) {
        final shares = sharesOf(n);
        expect(SummaryRules.topCategories(shares), same(shares), reason: '$n');
      }
    });

    test('con más de 6: las 5 mayores y «Otras» con la suma del resto', () {
      final shares = sharesOf(8); // 8000, 7000, ..., 1000
      final top = SummaryRules.topCategories(shares);

      expect(top, hasLength(6));
      expect(
        [for (final s in top.take(5)) s.name],
        ['Cat 8', 'Cat 7', 'Cat 6', 'Cat 5', 'Cat 4'],
      );
      final others = top.last;
      expect(others.name, 'Otras');
      expect(others.categoryId, isNull, reason: 'no se puede abrir');
      expect(others.totalCents, 3000 + 2000 + 1000);
      expect(others.count, 3 + 2 + 1);
      expect(others.share, closeTo(6000 / 36000, 1e-9));
    });

    test('el total y las partes siguen sumando lo mismo tras agrupar', () {
      final shares = sharesOf(9);
      final top = SummaryRules.topCategories(shares);
      expect(SummaryRules.groupTotal(top), SummaryRules.groupTotal(shares));
      expect(top.fold<double>(0, (sum, s) => sum + s.share), closeTo(1, 1e-9));
    });

    test('con max distinto respeta el límite', () {
      final top = SummaryRules.topCategories(sharesOf(5), max: 3);
      expect(top.map((s) => s.name), ['Cat 5', 'Cat 4', 'Otras']);
      expect(top.last.totalCents, 3000 + 2000 + 1000);
    });

    test('no cambia la lista original', () {
      final shares = sharesOf(8);
      SummaryRules.topCategories(shares);
      expect(shares, hasLength(8));
    });
  });

  group('SummaryRules.deltaPercent', () {
    test(
      'mes anterior en cero (o negativo): null, no hay con qué comparar',
      () {
        expect(SummaryRules.deltaPercent(5000, 0), isNull);
        expect(SummaryRules.deltaPercent(0, 0), isNull);
        expect(SummaryRules.deltaPercent(5000, -1), isNull);
      },
    );

    test('sube: porcentaje positivo', () {
      expect(SummaryRules.deltaPercent(150, 100), 50);
      expect(SummaryRules.deltaPercent(300, 100), 200);
    });

    test('baja: porcentaje negativo; a cero es -100', () {
      expect(SummaryRules.deltaPercent(50, 100), -50);
      expect(SummaryRules.deltaPercent(0, 100), -100);
    });

    test('igual: 0', () {
      expect(SummaryRules.deltaPercent(100, 100), 0);
    });

    test('redondea al entero más cercano', () {
      expect(SummaryRules.deltaPercent(101, 300), -66); // -66,33
      expect(SummaryRules.deltaPercent(10001, 3000), 233); // 233,36
      expect(SummaryRules.deltaPercent(1005, 1000), 1); // 0,5 → 1
      expect(SummaryRules.deltaPercent(1004, 1000), 0); // 0,4 → 0
    });
  });

  group('SummaryRules.methodComparison', () {
    final income = MovementType.income;

    test('une los medios de ambos meses y ordena por este mes (desc)', () {
      final rows = SummaryRules.methodComparison(
        current: [
          buildMethodTotal(type: income, id: 1, name: 'Nequi', totalCents: 500),
          buildMethodTotal(
            type: income,
            id: 2,
            name: 'Efectivo',
            totalCents: 900,
          ),
        ],
        previous: [
          buildMethodTotal(type: income, id: 1, name: 'Nequi', totalCents: 400),
          buildMethodTotal(
            type: income,
            id: 2,
            name: 'Efectivo',
            totalCents: 1000,
          ),
        ],
        type: income,
      );

      expect([for (final r in rows) r.name], ['Efectivo', 'Nequi']);
      expect(rows.first.currentCents, 900);
      expect(rows.first.previousCents, 1000);
      expect(rows.first.deltaPercent, -10);
      expect(rows.last.deltaPercent, 25);
    });

    test(
      'un medio que solo existió el mes pasado aparece con este mes en 0',
      () {
        final rows = SummaryRules.methodComparison(
          current: [
            buildMethodTotal(
              type: income,
              id: 1,
              name: 'Nequi',
              totalCents: 500,
            ),
          ],
          previous: [
            buildMethodTotal(
              type: income,
              id: 9,
              name: 'Daviplata',
              totalCents: 700,
            ),
          ],
          type: income,
        );

        expect([for (final r in rows) r.name], ['Nequi', 'Daviplata']);
        final old = rows.last;
        expect(old.currentCents, 0);
        expect(old.previousCents, 700);
        expect(old.deltaPercent, -100);
      },
    );

    test('un medio nuevo este mes: sin variación (el mes pasado fue 0)', () {
      final rows = SummaryRules.methodComparison(
        current: [
          buildMethodTotal(type: income, id: 1, name: 'Nequi', totalCents: 500),
        ],
        previous: const [],
        type: income,
      );
      expect(rows.single.previousCents, 0);
      expect(rows.single.deltaPercent, isNull);
    });

    test('solo cuenta el tipo pedido', () {
      final rows = SummaryRules.methodComparison(
        current: [
          buildMethodTotal(type: income, id: 1, totalCents: 500),
          buildMethodTotal(id: 1, totalCents: 70),
        ],
        previous: [buildMethodTotal(id: 1, totalCents: 90)],
        type: MovementType.expense,
      );
      expect(rows.single.currentCents, 70);
      expect(rows.single.previousCents, 90);
    });

    test('empate este mes: desempata por el mes pasado (mayor primero)', () {
      final rows = SummaryRules.methodComparison(
        current: [
          buildMethodTotal(type: income, id: 1, name: 'A', totalCents: 100),
          buildMethodTotal(type: income, id: 2, name: 'B', totalCents: 100),
        ],
        previous: [
          buildMethodTotal(type: income, id: 1, name: 'A', totalCents: 10),
          buildMethodTotal(type: income, id: 2, name: 'B', totalCents: 50),
        ],
        type: income,
      );
      expect([for (final r in rows) r.name], ['B', 'A']);
    });

    test('sin datos en ninguno de los dos meses: lista vacía', () {
      expect(
        SummaryRules.methodComparison(
          current: const [],
          previous: const [],
          type: income,
        ),
        isEmpty,
      );
    });
  });

  group('SummaryRules.trendBars', () {
    test(
      'una barra por mes con su etiqueta corta y los totales del servidor',
      () {
        final bars = SummaryRules.trendBars([
          MonthlyPoint(
            month: DateTime(2026, 5),
            summary: buildMonthSummary(
              totals: buildTotals(incomeCents: 1000, expenseCents: 400),
            ),
          ),
          MonthlyPoint(
            month: DateTime(2026, 6),
            summary: buildMonthSummary(
              totals: buildTotals(incomeCents: 0, expenseCents: 900),
            ),
          ),
        ]);

        expect(bars, hasLength(2));
        expect(bars[0].label, 'May');
        expect(bars[0].month, DateTime(2026, 5));
        expect(bars[0].incomeCents, 1000);
        expect(bars[0].expenseCents, 400);
        expect(bars[1].label, 'Jun');
        expect(bars[1].incomeCents, 0);
        expect(bars[1].expenseCents, 900);
      },
    );

    test('sin puntos: lista vacía', () {
      expect(SummaryRules.trendBars(const []), isEmpty);
    });
  });

  group('SummaryRules.methodsOf', () {
    test('sin filas: lista vacía', () {
      expect(SummaryRules.methodsOf(const [], MovementType.income), isEmpty);
      expect(SummaryRules.methodsOf(const [], MovementType.expense), isEmpty);
    });

    test('deja solo las filas del tipo pedido', () {
      final rows = [
        buildMethodTotal(type: MovementType.income, id: 1, totalCents: 500),
        buildMethodTotal(id: 2, totalCents: 700),
        buildMethodTotal(type: MovementType.income, id: 3, totalCents: 900),
      ];

      final income = SummaryRules.methodsOf(rows, MovementType.income);
      final expense = SummaryRules.methodsOf(rows, MovementType.expense);

      expect(income.map((r) => r.methodId), [3, 1]);
      expect(income.every((r) => r.type == MovementType.income), isTrue);
      expect(expense.map((r) => r.methodId), [2]);
    });

    test(
      'un medio con ingresos y gastos aparece en cada lista con lo suyo',
      () {
        final rows = [
          buildMethodTotal(type: MovementType.income, id: 4, totalCents: 1000),
          buildMethodTotal(id: 4, totalCents: 300),
        ];

        expect(
          SummaryRules.methodsOf(rows, MovementType.income).single.totalCents,
          1000,
        );
        expect(
          SummaryRules.methodsOf(rows, MovementType.expense).single.totalCents,
          300,
        );
      },
    );

    test('excluye los totales en 0 (borde: 0 fuera, 1 centavo dentro)', () {
      final rows = [
        buildMethodTotal(id: 1, name: 'Cero', totalCents: 0),
        buildMethodTotal(id: 2, name: 'Un centavo', totalCents: 1),
      ];

      final result = SummaryRules.methodsOf(rows, MovementType.expense);

      expect(result.map((r) => r.name), ['Un centavo']);
    });

    test('si todos los totales son 0, queda vacío', () {
      final rows = [
        buildMethodTotal(id: 1, totalCents: 0),
        buildMethodTotal(id: 2, totalCents: 0),
      ];

      expect(SummaryRules.methodsOf(rows, MovementType.expense), isEmpty);
    });

    test('ordena de mayor a menor total', () {
      final rows = [
        buildMethodTotal(id: 1, name: 'Chico', totalCents: 100),
        buildMethodTotal(id: 2, name: 'Grande', totalCents: 9000),
        buildMethodTotal(id: 3, name: 'Mediano', totalCents: 2500),
      ];

      final result = SummaryRules.methodsOf(rows, MovementType.expense);

      expect(result.map((r) => r.name), ['Grande', 'Mediano', 'Chico']);
    });

    test('con el mismo total desempata por nombre (A→Z)', () {
      final rows = [
        buildMethodTotal(id: 1, name: 'Nequi', totalCents: 5000),
        buildMethodTotal(id: 2, name: 'Bancolombia', totalCents: 5000),
        buildMethodTotal(id: 3, name: 'Efectivo', totalCents: 5000),
        buildMethodTotal(id: 4, name: 'Zeta', totalCents: 8000),
      ];

      final result = SummaryRules.methodsOf(rows, MovementType.expense);

      expect(result.map((r) => r.name), [
        'Zeta',
        'Bancolombia',
        'Efectivo',
        'Nequi',
      ]);
    });

    test('no modifica la lista original', () {
      final rows = [
        buildMethodTotal(id: 1, name: 'B', totalCents: 100),
        buildMethodTotal(id: 2, name: 'A', totalCents: 900),
      ];

      SummaryRules.methodsOf(rows, MovementType.expense);

      expect(rows.map((r) => r.name), ['B', 'A']);
    });
  });
}
