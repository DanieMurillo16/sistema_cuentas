import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stats_row.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/visibility_toggle_button.dart';

/// Tarjeta grande del mes: «Balance disponible» (flujo neto que calcula el
/// servidor) con Ingresos y Gastos debajo. La cifra cuenta al aparecer y se
/// desliza al valor nuevo cuando cambia.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totals,
    required this.hidden,
    this.methods = const [],
    this.onToggleHidden,
    this.incomeKey,
    this.expenseKey,
    this.onIncomeTap,
    this.onExpenseTap,
  });

  final SummaryTotals totals;
  final bool hidden;

  /// Lo que entró y salió por cada medio de pago, para el detalle pequeño.
  final List<MethodTotal> methods;

  /// El ojo propio de la tarjeta: tapa solo las cifras de ella.
  final VoidCallback? onToggleHidden;
  final Key? incomeKey;
  final Key? expenseKey;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: AppColors.onBrandBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.balanceStart, AppColors.balanceEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Balance disponible',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.onBrandMuted,
                    ),
                  ),
                ),
                if (onToggleHidden != null)
                  VisibilityToggleButton(
                    compact: true,
                    hidden: hidden,
                    onTap: onToggleHidden!,
                    color: AppColors.onBrandMuted,
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceXs),
            AnimatedNumberText(
              value: centsToPesos(totals.netFlowCents),
              obscured: hidden,
              style: textTheme.displaySmall?.copyWith(color: AppColors.onBrand),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            BalanceStatsRow(
              totals: totals,
              hidden: hidden,
              methods: methods,
              incomeKey: incomeKey,
              expenseKey: expenseKey,
              onIncomeTap: onIncomeTap,
              onExpenseTap: onExpenseTap,
            ),
          ],
        ),
      ),
    );
  }
}
