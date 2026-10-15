import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Lo que dejó cada medio de pago (Nequi, Bancolombia, efectivo…) bajo el total
/// de una tarjeta del balance, en letra pequeña. Con el ojo cerrado, sin cifras.
class BalanceMethodLines extends StatelessWidget {
  const BalanceMethodLines({
    super.key,
    required this.methods,
    required this.hidden,
  });

  final List<MethodTotal> methods;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in methods)
          Padding(
            key: ValueKey(
              'balance-method-${method.type.apiValue}-'
              '${method.methodId}',
            ),
            padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
            // Nombre e importe en la misma línea si caben; si no, el importe
            // baja: ninguno se parte ni se sale de la tarjeta.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: DesignTokens.spaceSm,
              children: [
                Text(
                  formatDisplayText(method.name),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onBrandMuted,
                  ),
                ),
                Text(
                  hidden
                      ? AnimatedNumberText.mask
                      : formatCents(method.totalCents),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onBrand,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
