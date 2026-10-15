import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Un medio de pago: lo de este mes frente al mes pasado, en dos barras finas y
/// con el cambio en %. Subir ingresos es bueno (verde); subir gastos, no (rojo).
/// Si el mes pasado no tuvo nada en ese medio, solo se ve este mes: una barra
/// vacía no dice nada.
class MethodComparisonTile extends StatelessWidget {
  const MethodComparisonTile({
    super.key,
    required this.comparison,
    required this.highest,
    required this.income,
    required this.hidden,
  });

  final MethodComparison comparison;

  /// El valor más alto de la lista (las barras se miden contra él).
  final int highest;
  final bool income;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = income ? AppColors.income : AppColors.expense;
    final delta = comparison.deltaPercent;
    final up = (delta ?? 0) >= 0;
    final good = income ? up : !up;
    String money(int cents) =>
        hidden ? AnimatedNumberText.mask : formatCents(cents);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDisplayText(comparison.name),
                  style: textTheme.titleSmall,
                ),
              ),
              if (delta != null)
                Text(
                  '${up ? '▲' : '▼'} ${delta.abs()} %',
                  style: textTheme.labelMedium?.copyWith(
                    color: good ? AppColors.income : AppColors.expense,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXs),
          _Line(
            fraction: highest == 0 ? 0 : comparison.currentCents / highest,
            color: color,
            text: 'Este mes ${money(comparison.currentCents)}',
          ),
          if (comparison.previousCents > 0) ...[
            const SizedBox(height: DesignTokens.spaceXs),
            _Line(
              fraction: comparison.previousCents / highest,
              color: AppColors.muted,
              text: 'Mes pasado ${money(comparison.previousCents)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.fraction,
    required this.color,
    required this.text,
  });

  final double fraction;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: DesignTokens.barHeight,
            color: color,
            backgroundColor: AppColors.surfaceHigh,
          ),
        ),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
