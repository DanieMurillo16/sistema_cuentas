import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_amount_text.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_icon.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/widgets/dot_separated_text.dart';

/// La tarjeta de un acuerdo: icono, con quién es y de qué, su día y su valor.
/// Al tocarla se abre su detalle.
class RecurringTileBody extends StatelessWidget {
  const RecurringTileBody({
    super.key,
    required this.payment,
    required this.hidden,
    required this.onTap,
  });

  final RecurringPayment payment;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Sin Card: la tarjeta (borde, esquinas, fondo) la pone `SwipeCard`.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Row(
          children: [
            MovementIcon(type: payment.type, categoryId: payment.categoryId),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RecurringRules.title(payment),
                    style: textTheme.titleSmall,
                  ),
                  DotSeparatedText(
                    parts: RecurringRules.subtitleParts(payment),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            MovementAmountText(
              text: formatCents(payment.valueCents),
              income: payment.isIncome,
              hidden: hidden,
            ),
          ],
        ),
      ),
    );
  }
}
