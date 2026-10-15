import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';

/// El estilo común de las gráficas del resumen: sin ejes laterales, con el mes
/// debajo y una cuadrícula horizontal muy tenue. Así todas se ven iguales.
abstract final class ChartStyle {
  static FlTitlesData monthTitles(List<MonthBar> bars, TextStyle? style) =>
      FlTitlesData(
        leftTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
              child: Text(bars[value.toInt()].label, style: style),
            ),
          ),
        ),
      );

  static FlGridData grid(double maxY) => FlGridData(
    drawVerticalLine: false,
    horizontalInterval: maxY / 4,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: AppColors.border, strokeWidth: 1),
  );

  static Color tooltipColor(Object? _) => AppColors.surfaceHigh;

  static TextStyle? tooltipText(TextStyle? base, Color color) =>
      base?.copyWith(color: color, fontWeight: FontWeight.w700);
}
