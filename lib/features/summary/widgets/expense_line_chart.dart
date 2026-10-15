import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/chart_style.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Cuánto se gastó cada mes, como una línea suave con el área debajo. Tocar un
/// punto muestra el mes y su monto (tapado si el ojo está cerrado).
class ExpenseLineChart extends StatelessWidget {
  const ExpenseLineChart({super.key, required this.bars, required this.hidden});

  final List<MonthBar> bars;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final highest = bars.fold<int>(
      0,
      (max, b) => b.expenseCents > max ? b.expenseCents : max,
    );
    final maxY = highest == 0 ? 1.0 : highest * 1.25;
    return Semantics(
      label: hidden
          ? 'Tendencia de gastos, montos ocultos'
          : 'Tendencia de gastos de los últimos ${bars.length} meses',
      child: SizedBox(
        height: DesignTokens.chartHeight,
        child: LineChart(
          duration: motionDuration(context, DesignTokens.animationNumber),
          curve: DesignTokens.curve,
          LineChartData(
            minY: 0,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: ChartStyle.grid(maxY),
            titlesData: ChartStyle.monthTitles(bars, textTheme.bodySmall),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                getTooltipColor: ChartStyle.tooltipColor,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${bars[spot.x.toInt()].label}\n${hidden ? AnimatedNumberText.mask : formatCents(bars[spot.x.toInt()].expenseCents)}',
                      ChartStyle.tooltipText(
                        textTheme.bodySmall,
                        AppColors.expense,
                      )!,
                    ),
                ],
              ),
            ),
            lineBarsData: [_series()],
          ),
        ),
      ),
    );
  }

  LineChartBarData _series() => LineChartBarData(
    spots: [
      for (final (i, bar) in bars.indexed)
        FlSpot(i.toDouble(), bar.expenseCents.toDouble()),
    ],
    isCurved: true,
    preventCurveOverShooting: true,
    color: AppColors.expense,
    barWidth: DesignTokens.chartLineWidth,
    dotData: const FlDotData(),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.expense.withValues(alpha: 0.3),
          AppColors.transparent,
        ],
      ),
    ),
  );
}
