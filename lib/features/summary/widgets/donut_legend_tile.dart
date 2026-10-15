import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/label_amount_row.dart';

/// Una fila de la leyenda de la dona: punto de color, nombre, monto y su parte
/// del total. Si se puede abrir (una categoría), muestra la flecha.
class DonutLegendTile extends StatelessWidget {
  const DonutLegendTile({
    super.key,
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
    required this.hidden,
    this.onTap,
  });

  final Color color;
  final String name;
  final String amount;
  final int percent;
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
        child: LabelAmountRow(
          leading: Padding(
            padding: const EdgeInsets.only(
              right: DesignTokens.spaceSm + DesignTokens.spaceXs,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: DesignTokens.spaceMd - 4),
            ),
          ),
          label: Text(formatDisplayText(name), style: textTheme.bodyLarge),
          amount: Semantics(
            label: hidden ? 'Monto oculto' : '$amount, $percent por ciento',
            excludeSemantics: true,
            child: Text(
              hidden ? AnimatedNumberText.mask : '$amount · $percent %',
              maxLines: 1,
              softWrap: false,
              style: textTheme.titleSmall,
            ),
          ),
          trailing: onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ),
      ),
    );
  }
}
