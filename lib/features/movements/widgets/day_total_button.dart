import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_amount_text.dart';

/// El neto de un día con su ojito: tocarlo lo tapa o lo destapa, solo ese.
class DayTotalButton extends StatelessWidget {
  const DayTotalButton({
    super.key,
    required this.itemKey,
    required this.label,
    required this.text,
    required this.income,
    required this.hidden,
    required this.onTap,
  });

  final String itemKey;

  /// El nombre del día, para el lector de pantalla («Hoy»).
  final String label;
  final String text;
  final bool income;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hidden
          ? 'Mostrar el total de $label'
          : 'Ocultar el total de $label',
      // Con la cifra visible el lector también la dice.
      value: hidden ? null : text,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('day-total-$itemKey'),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.compactTapTarget,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MovementAmountText(
                text: text,
                income: income,
                hidden: hidden,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(width: DesignTokens.spaceXs),
              Icon(
                hidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: DesignTokens.iconSm,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
