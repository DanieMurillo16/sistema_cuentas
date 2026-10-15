import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/expense_line_chart.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/trend_async.dart';

/// Tendencia de gastos: cuánto se gastó cada mes, en una línea suave.
class SummaryExpenseTrendCard extends StatelessWidget {
  const SummaryExpenseTrendCard({super.key, required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return SummarySectionCard(
      title: 'Tendencia de gastos',
      subtitle: 'Últimos $trendMonths meses',
      child: TrendAsync(
        builder: (points) => ExpenseLineChart(
          bars: SummaryRules.trendBars(points),
          hidden: hidden,
        ),
      ),
    );
  }
}
