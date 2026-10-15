import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/models/summary_dues.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

import 'movement_fixtures.dart';

/// `resumen.por_categoria[i]` de `backend/docs/API.md`.
Map<String, dynamic> categoryTotalJson({
  String type = 'GASTO',
  int id = 3,
  String name = 'Alimentación',
  bool isCapital = false,
  String total = '420000.00',
  int count = 5,
}) => {
  'tipo': type,
  'id_categoria': id,
  'categoria': name,
  'es_capital': isCapital,
  'total': total,
  'cantidad': count,
};

/// `resumen.por_medio[i]`.
Map<String, dynamic> methodTotalJson({
  String type = 'GASTO',
  int id = 2,
  String name = 'Nequi',
  String total = '100000.00',
  int count = 2,
}) => {
  'tipo': type,
  'id_medio': id,
  'medio': name,
  'total': total,
  'cantidad': count,
};

/// `resumen.vencimientos[i]`.
Map<String, dynamic> summaryDuesJson({
  String type = 'INGRESO',
  String balance = '180000.00',
  String overdueBalance = '0.00',
  int pending = 1,
  int overdue = 0,
}) => {
  'tipo': type,
  'cantidad': pending,
  'esperado': balance,
  'pagado': '0.00',
  'saldo': balance,
  'cantidad_pendiente': pending,
  'cantidad_vencida': overdue,
  'saldo_vencido': overdueBalance,
};

/// El `data` completo de `resumen/mes.php`.
Map<String, dynamic> monthSummaryJson({
  Map<String, dynamic>? totals,
  List<Map<String, dynamic>>? byCategory,
  List<Map<String, dynamic>>? byMethod,
  List<Map<String, dynamic>>? dues,
}) => {
  'totales': totals ?? summaryTotalsJson(),
  'por_categoria':
      byCategory ??
      [
        categoryTotalJson(
          type: 'INGRESO',
          id: 9,
          name: 'Salario',
          total: '1500000.00',
          count: 1,
        ),
        categoryTotalJson(),
      ],
  'por_medio':
      byMethod ??
      [
        methodTotalJson(type: 'INGRESO', total: '1500000.00', count: 1),
        methodTotalJson(total: '420000.50', count: 5),
      ],
  'vencimientos':
      dues ??
      [
        summaryDuesJson(),
        summaryDuesJson(
          type: 'GASTO',
          balance: '90000.00',
          overdueBalance: '30000.00',
          overdue: 1,
        ),
      ],
};

CategoryTotal buildCategoryTotal({
  MovementType type = MovementType.expense,
  int id = 3,
  String name = 'Alimentación',
  bool isCapital = false,
  int totalCents = 42000000,
  int count = 5,
}) => CategoryTotal(
  type: type,
  categoryId: id,
  name: name,
  isCapital: isCapital,
  totalCents: totalCents,
  count: count,
);

MethodTotal buildMethodTotal({
  MovementType type = MovementType.expense,
  int id = 2,
  String name = 'Nequi',
  int totalCents = 10000000,
  int count = 2,
}) => MethodTotal(
  type: type,
  methodId: id,
  name: name,
  totalCents: totalCents,
  count: count,
);

SummaryDues buildSummaryDues({
  MovementType type = MovementType.income,
  int balanceCents = 18000000,
  int overdueBalanceCents = 0,
  int pendingCount = 1,
  int overdueCount = 0,
}) => SummaryDues(
  type: type,
  balanceCents: balanceCents,
  overdueBalanceCents: overdueBalanceCents,
  pendingCount: pendingCount,
  overdueCount: overdueCount,
);

/// Un resumen completo con valores típicos. Los parámetros reemplazan cada parte.
MonthSummary buildMonthSummary({
  SummaryTotals? totals,
  List<CategoryTotal>? byCategory,
  List<MethodTotal>? byMethod,
  List<SummaryDues>? dues,
}) => MonthSummary(
  totals: totals ?? buildTotals(),
  byCategory:
      byCategory ??
      [
        buildCategoryTotal(
          type: MovementType.income,
          id: 9,
          name: 'Salario',
          totalCents: 150000000,
          count: 1,
        ),
        buildCategoryTotal(),
      ],
  byMethod:
      byMethod ??
      [
        buildMethodTotal(
          type: MovementType.income,
          totalCents: 150000000,
          count: 1,
        ),
        buildMethodTotal(totalCents: 42000050, count: 5),
      ],
  dues:
      dues ??
      [
        buildSummaryDues(),
        buildSummaryDues(
          type: MovementType.expense,
          balanceCents: 9000000,
          overdueBalanceCents: 3000000,
          overdueCount: 1,
        ),
      ],
);

/// Un resumen con nombres de 40+ caracteres en categorías y medios, cifras de
/// 12 dígitos y capital, para probar que nada se desborda.
MonthSummary buildLongMonthSummary() => buildMonthSummary(
  totals: SummaryTotals(
    incomeTotalCents: 99999999999900,
    expenseTotalCents: 99999999999900,
    netFlowCents: -99999999999900,
    operatingBalanceCents: 99999999999900,
    capitalRecoveredCents: 5000000,
    capitalDeliveredCents: 3000000,
    movementCount: 12345,
  ),
  byCategory: [
    for (var i = 0; i < 6; i++) ...[
      buildCategoryTotal(
        type: MovementType.income,
        id: 100 + i,
        name: '$longCatalogName $i',
        totalCents: 99999999999900 - i,
      ),
      buildCategoryTotal(
        id: 200 + i,
        name: '$longCatalogName $i',
        totalCents: 99999999999900 - i,
      ),
    ],
  ],
  byMethod: [
    for (var i = 0; i < 4; i++) ...[
      buildMethodTotal(
        type: MovementType.income,
        id: 300 + i,
        name: '$longCatalogName $i',
        totalCents: 99999999999900,
      ),
      buildMethodTotal(
        id: 300 + i,
        name: '$longCatalogName $i',
        totalCents: 99999999999900,
      ),
    ],
  ],
  dues: [
    buildSummaryDues(
      balanceCents: 99999999999900,
      overdueBalanceCents: 99999999999900,
      overdueCount: 99,
    ),
    buildSummaryDues(
      type: MovementType.expense,
      balanceCents: 99999999999900,
      overdueBalanceCents: 99999999999900,
      overdueCount: 99,
    ),
  ],
);
