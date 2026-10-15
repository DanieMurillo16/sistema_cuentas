import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/summary_dues.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

/// El resumen de un mes tal como lo calcula el servidor: totales, desglose por
/// categoría y por medio de pago, y lo que falta por cobrar y pagar.
class MonthSummary {
  const MonthSummary({
    required this.totals,
    required this.byCategory,
    required this.byMethod,
    required this.dues,
  });

  final SummaryTotals totals;
  final List<CategoryTotal> byCategory;
  final List<MethodTotal> byMethod;
  final List<SummaryDues> dues;

  /// Sin movimientos **y** sin nada pendiente: solo entonces no hay qué mostrar
  /// (un mes con vencimientos y sin pagos todavía tiene mucho que decir).
  bool get isEmpty =>
      totals.movementCount == 0 && dues.every((d) => d.pendingCount == 0);

  /// Lo que falta de un tipo; en cero si el mes no tiene vencimientos de ese tipo.
  SummaryDues duesFor(MovementType type) => dues.firstWhere(
    (d) => d.type == type,
    orElse: () => SummaryDues(
      type: type,
      balanceCents: 0,
      overdueBalanceCents: 0,
      pendingCount: 0,
      overdueCount: 0,
    ),
  );
}
