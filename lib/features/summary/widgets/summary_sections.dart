import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_capital_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/method_comparison_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_donut_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_expense_trend_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_dues_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_methods_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_totals_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_trend_card.dart';

/// Las secciones del resumen: primero por dónde entra y sale el dinero, luego
/// las categorías (dona), y después el mes, lo pendiente, la tendencia de los
/// últimos meses y lo que dejó cada medio. El capital solo aparece si lo hay.
/// Cada una mide [columnWidth].
class SummarySections extends StatelessWidget {
  const SummarySections({
    super.key,
    required this.summary,
    required this.hidden,
    required this.columnWidth,
  });

  final MonthSummary summary;
  final bool hidden;
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    final totals = summary.totals;
    final hasCapital =
        totals.capitalRecoveredCents != 0 || totals.capitalDeliveredCents != 0;
    final sections = <Widget>[
      MethodComparisonCard(summary: summary, hidden: hidden),
      SummaryDonutCard(rows: summary.byCategory, hidden: hidden),
      SummaryTotalsCard(totals: totals, hidden: hidden),
      SummaryDuesCard(summary: summary, hidden: hidden),
      SummaryTrendCard(hidden: hidden),
      SummaryExpenseTrendCard(hidden: hidden),
      SummaryMethodsCard(rows: summary.byMethod, hidden: hidden),
      if (hasCapital) SummaryCapitalCard(totals: totals, hidden: hidden),
    ];
    return Wrap(
      spacing: DesignTokens.spaceMd,
      runSpacing: DesignTokens.spaceMd,
      children: [
        for (final section in sections)
          SizedBox(width: columnWidth, child: section),
      ],
    );
  }
}
