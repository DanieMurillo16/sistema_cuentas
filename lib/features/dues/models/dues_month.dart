import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/models/due_totals.dart';

/// Los vencimientos de un mes con sus totales por tipo.
class DuesMonth {
  const DuesMonth({required this.dues, required this.totals});

  final List<Due> dues;
  final List<DueTotals> totals;

  /// Totales de un tipo; en cero si el mes no tiene vencimientos de ese tipo.
  DueTotals totalsFor(MovementType type) => totals.firstWhere(
    (t) => t.type == type,
    orElse: () => DueTotals(
      type: type,
      count: 0,
      expectedCents: 0,
      paidCents: 0,
      balanceCents: 0,
      pendingCount: 0,
      overdueCount: 0,
    ),
  );
}
