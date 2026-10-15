import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/trend_async.dart';
import 'package:sistema_cuentas/features/summary/widgets/trend_bars_chart.dart';

/// Ingresos frente a gastos de los últimos meses (barras): dónde estás parado
/// y hacia dónde vas.
class SummaryTrendCard extends StatelessWidget {
  const SummaryTrendCard({super.key, required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return SummarySectionCard(
      title: 'Ingresos vs gastos',
      subtitle: 'Últimos $trendMonths meses · toca un mes para ver las cifras',
      child: TrendAsync(
        builder: (points) => TrendBarsChart(
          bars: SummaryRules.trendBars(points),
          hidden: hidden,
        ),
      ),
    );
  }
}
