import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_content.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';

/// Resumen del mes: totales, por medio de pago, por categoría y lo pendiente.
/// pantalla → monthSummaryProvider → SummaryRepository → resumen/mes.php
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView(
      state: ref.watch(monthSummaryProvider),
      isEmpty: (summary) => summary.isEmpty,
      emptyIcon: Icons.bar_chart_outlined,
      emptyTitle: 'Sin movimientos este mes',
      emptyMessage:
          'Cuando registres ingresos o gastos, aquí verás el resumen.',
      onRetry: () => ref.invalidate(monthSummaryProvider),
      builder: (summary) => SummaryContent(summary: summary),
    );
  }
}
