import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/models/monthly_point.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Cuántos meses muestran las gráficas (el elegido y los anteriores).
const trendMonths = 6;

/// El resumen de un mes cualquiera (los meses anteriores de las gráficas). Se
/// guarda por mes: cambiar de mes en la cabecera reutiliza lo ya pedido.
final summaryForMonthProvider = FutureProvider.family<MonthSummary, DateTime>((
  ref,
  month,
) {
  ref.watch(sessionUserIdProvider);
  return ref.read(summaryRepositoryProvider).month(month);
});

/// El mes anterior al elegido, para comparar («este mes vs el pasado»).
final previousMonthSummaryProvider = FutureProvider<MonthSummary>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(summaryForMonthProvider(monthsBefore(month, 1)).future);
});

/// Los últimos [trendMonths] meses hasta el elegido, del más viejo al más
/// nuevo. El mes elegido sale de [monthSummaryProvider] (se actualiza con cada
/// pago o movimiento); los anteriores, del resumen guardado por mes.
final monthlyTrendProvider = FutureProvider<List<MonthlyPoint>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final current = await ref.watch(monthSummaryProvider.future);
  final past = await Future.wait([
    for (var back = trendMonths - 1; back >= 1; back--)
      ref.watch(summaryForMonthProvider(monthsBefore(month, back)).future),
  ]);
  return [
    for (var i = 0; i < past.length; i++)
      MonthlyPoint(
        month: monthsBefore(month, trendMonths - 1 - i),
        summary: past[i],
      ),
    MonthlyPoint(month: month, summary: current),
  ];
});
