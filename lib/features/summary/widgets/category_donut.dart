import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/donut_center.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// La dona de categorías: un trozo por categoría. Tocar un trozo lo resalta y
/// el centro muestra esa categoría; sin selección, el total. Con el ojo cerrado
/// las cifras van tapadas.
class CategoryDonut extends StatefulWidget {
  const CategoryDonut({
    super.key,
    required this.shares,
    required this.totalCents,
    required this.income,
    required this.hidden,
  });

  final List<CategoryShare> shares;
  final int totalCents;
  final bool income;
  final bool hidden;

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut> {
  // Estado efímero y visual: el trozo tocado. Permitido con setState.
  int? _selected;

  String _money(int cents) =>
      widget.hidden ? AnimatedNumberText.mask : formatCents(cents);

  void _touch(FlTouchEvent event, PieTouchResponse? response) {
    if (event is! FlTapUpEvent) return;
    // Tocar fuera de un trozo da índice -1 (o nada): se deselecciona.
    final touched = response?.touchedSection?.touchedSectionIndex;
    final index = (touched == null || touched < 0) ? null : touched;
    setState(() => _selected = index == _selected ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        _selected != null &&
            _selected! >= 0 &&
            _selected! < widget.shares.length
        ? widget.shares[_selected!]
        : null;
    final kind = widget.income ? 'Ingresos' : 'Gastos';
    return Semantics(
      label: widget.hidden
          ? '$kind por categoría, monto oculto'
          : '$kind por categoría, total ${formatCents(widget.totalCents)}',
      excludeSemantics: true,
      child: SizedBox(
        width: DesignTokens.donutSize,
        height: DesignTokens.donutSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              duration: motionDuration(context, DesignTokens.animationNormal),
              curve: DesignTokens.curve,
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: widget.shares.length > 1
                    ? DesignTokens.donutSliceGap
                    : 0,
                centerSpaceRadius: DesignTokens.donutCenterRadius,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(touchCallback: _touch),
                sections: [
                  for (final (i, share) in widget.shares.indexed)
                    PieChartSectionData(
                      value: share.totalCents.toDouble(),
                      color: AppColors.chart[i % AppColors.chart.length],
                      showTitle: false,
                      radius: i == _selected
                          ? DesignTokens.donutThicknessSelected
                          : DesignTokens.donutThickness,
                    ),
                ],
              ),
            ),
            DonutCenter(
              value: _money(selected?.totalCents ?? widget.totalCents),
              label: selected == null
                  ? (widget.income ? 'ingresado' : 'gastado')
                  : formatDisplayText(selected.name),
            ),
          ],
        ),
      ),
    );
  }
}
