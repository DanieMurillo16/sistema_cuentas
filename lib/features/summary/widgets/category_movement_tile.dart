import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_amount_text.dart';

/// Un movimiento de la hoja de una categoría: qué fue, cuándo, con qué medio y
/// cuánto.
class CategoryMovementTile extends StatelessWidget {
  const CategoryMovementTile({
    super.key,
    required this.movement,
    required this.hidden,
  });

  final Movement movement;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDisplayText(movement.description),
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    '${formatShortDate(movement.date)} · ${formatDisplayText(movement.method)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            MovementAmountText(
              text: formatCentsSigned(movement.signedCents),
              income: movement.isIncome,
              hidden: hidden,
            ),
          ],
        ),
      ),
    );
  }
}
