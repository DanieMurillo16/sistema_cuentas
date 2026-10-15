import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_tile_actions.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_amount_text.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_icon.dart';
import 'package:sistema_cuentas/shared/widgets/dot_separated_text.dart';

/// Lo de dentro de una fila de «Este mes»: con quién es y de qué, la fecha, lo
/// que falta y el pie con el estado y el botón de Cobrar / Pagar.
class DueTileBody extends StatelessWidget {
  const DueTileBody({
    super.key,
    required this.due,
    required this.hidden,
    required this.onPay,
  });

  final Due due;
  final bool hidden;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MovementIcon(type: due.type, categoryId: due.categoryId),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DuesRules.tileTitle(due), style: textTheme.titleSmall),
                    DotSeparatedText(parts: DuesRules.tileSubtitleParts(due)),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              MovementAmountText(
                text: formatCents(due.balanceCents),
                income: due.isIncome,
                hidden: hidden,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          DueTileActions(due: due, onPay: onPay),
        ],
      ),
    );
  }
}
