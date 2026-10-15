import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';

/// Repositorio del resumen falso. Con [onMonthTotals] solo hay totales (sin
/// desglose); con [onMonth] se arma el resumen completo.
class FakeSummaryRepository implements SummaryRepository {
  FakeSummaryRepository(this.onMonthTotals, {this.onMonth});

  Future<SummaryTotals> Function(DateTime month) onMonthTotals;
  Future<MonthSummary> Function(DateTime month)? onMonth;

  int calls = 0;
  final months = <DateTime>[];

  @override
  Future<MonthSummary> month(DateTime month) async {
    calls++;
    months.add(month);
    if (onMonth != null) return onMonth!(month);
    final totals = await onMonthTotals(month);
    return MonthSummary(
      totals: totals,
      byCategory: const [],
      byMethod: const [],
      dues: const [],
    );
  }
}
