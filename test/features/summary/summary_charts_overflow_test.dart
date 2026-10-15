import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/models/summary_dues.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';

import '../../helpers/movement_fixtures.dart';
import '../../support/fake_summary_repository.dart';
import '../../support/inicio_overrides.dart';
import '../../support/pump_at_sizes.dart';

void main() {
  testWidgets(
    'el resumen con dona, barras y comparación no desborda en ningún tamaño',
    (tester) async {
      final summary = MonthSummary(
        totals: buildTotals(),
        byCategory: [
          for (var i = 0; i < 9; i++)
            CategoryTotal(
              type: i.isEven ? MovementType.expense : MovementType.income,
              categoryId: i,
              name: 'Categoría con nombre bastante largo número $i',
              isCapital: false,
              totalCents: (i + 1) * 1234500,
              count: i + 1,
            ),
        ],
        byMethod: [
          for (var i = 0; i < 4; i++) ...[
            MethodTotal(
              type: MovementType.income,
              methodId: i,
              name: 'Medio $i',
              totalCents: 5000000 - i * 700000,
              count: 2,
            ),
            MethodTotal(
              type: MovementType.expense,
              methodId: i,
              name: 'Medio $i',
              totalCents: 900000 + i * 100000,
              count: 1,
            ),
          ],
        ],
        dues: const [
          SummaryDues(
            type: MovementType.income,
            balanceCents: 99000000,
            overdueBalanceCents: 5000000,
            pendingCount: 3,
            overdueCount: 2,
          ),
        ],
      );
      await expectNoOverflow(
        tester,
        const SummaryScreen(),
        overrides: dataOverrides(
          summary: FakeSummaryRepository(
            (_) async => buildTotals(),
            onMonth: (_) async => summary,
          ),
        ),
      );
    },
  );
}
