import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/chart_style.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Ingresos y gastos mes a mes en barras. Tocar un mes muestra sus cifras en un
/// globo; con el ojo cerrado, tapadas.
class TrendBarsChart extends StatelessWidget {
  const TrendBarsChart({super.key, required this.bars, required this.hidden});

  final List<MonthBar> bars;
  final bool hidden;

  String _money(int cents) =>
      hidden ? AnimatedNumberText.mask : formatCents(cents);

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final highest = bars.fold<int>(
      0,
      (max, b) =>
          [max, b.incomeCents, b.expenseCents].reduce((a, c) => a > c ? a : c),
    );
    final maxY = highest == 0 ? 1.0 : highest * 1.2;
    return Semantics(
      label: hidden
          ? 'Ingresos y gastos por mes, montos ocultos'
          : 'Ingresos y gastos de los últimos ${bars.length} meses',
      child: SizedBox(
        height: DesignTokens.chartHeight,
        child: BarChart(
          duration: motionDuration(context, DesignTokens.animationNumber),
          curve: DesignTokens.curve,
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: ChartStyle.grid(maxY),
            titlesData: ChartStyle.monthTitles(bars, textTheme.bodySmall),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                getTooltipColor: ChartStyle.tooltipColor,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final bar = bars[groupIndex];
                  final income = rodIndex == 0;
                  return BarTooltipItem(
                    '${bar.label}\n${income ? 'Ingresos' : 'Gastos'} ${_money(income ? bar.incomeCents : bar.expenseCents)}',
                    ChartStyle.tooltipText(
                      textTheme.bodySmall,
                      income ? AppColors.income : AppColors.expense,
                    )!,
                  );
                },
              ),
            ),
            barGroups: [
              for (final (i, bar) in bars.indexed)
                BarChartGroupData(
                  x: i,
                  barsSpace: DesignTokens.spaceXs,
                  barRods: [
                    _rod(bar.incomeCents, AppColors.income),
                    _rod(bar.expenseCents, AppColors.expense),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartRodData _rod(int cents, Color color) => BarChartRodData(
    toY: cents.toDouble(),
    color: color,
    width: DesignTokens.chartBarWidth,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(DesignTokens.radiusSm / 2),
    ),
  );
}
