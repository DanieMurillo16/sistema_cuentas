import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

/// «Detalle ⌄» al pie de una tarjeta del balance: abre o cierra el desglose
/// por medio de pago. El chevron gira al abrir.
class BalanceMethodsToggle extends StatelessWidget {
  const BalanceMethodsToggle({
    super.key,
    required this.type,
    required this.expanded,
    required this.onTap,
  });

  final MovementType type;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        '${expanded ? 'Ocultar' : 'Ver'} '
        '${type.plural.toLowerCase()} por medio de pago';
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: ValueKey('balance-methods-toggle-${type.apiValue}'),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DesignTokens.compactTapTarget,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Detalle',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.onBrandMuted),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: motionDuration(context, DesignTokens.animationFast),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    size: DesignTokens.iconMd,
                    color: AppColors.onBrandMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
