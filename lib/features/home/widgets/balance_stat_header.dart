import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

/// La línea de arriba de una tarjeta del balance: icono, «Ingresos» o «Gastos»
/// y, si se puede tocar, la flecha.
class BalanceStatHeader extends StatelessWidget {
  const BalanceStatHeader({
    super.key,
    required this.type,
    required this.tappable,
  });

  final MovementType type;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          type.trendIcon,
          size: DesignTokens.iconMd,
          color: AppColors.onBrand,
        ),
        const SizedBox(width: DesignTokens.spaceSm),
        Expanded(
          child: Text(
            type.plural,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.onBrandMuted),
          ),
        ),
        if (tappable)
          const Icon(
            Icons.chevron_right_rounded,
            size: DesignTokens.iconMd,
            color: AppColors.onBrandMuted,
          ),
      ],
    );
  }
}
