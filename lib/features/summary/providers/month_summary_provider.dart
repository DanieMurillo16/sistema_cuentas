import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/summary/data/summary_repository.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// El resumen del mes elegido en la cabecera. Cada escritura (registrar, anular)
/// lo invalida: la pantalla conserva la cifra anterior hasta que llega la nueva.
final monthSummaryProvider = FutureProvider<MonthSummary>((ref) {
  ref.watch(sessionUserIdProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.read(summaryRepositoryProvider).month(month);
});
