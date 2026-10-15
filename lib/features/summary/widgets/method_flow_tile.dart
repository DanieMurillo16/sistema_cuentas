import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/label_amount_row.dart';

/// Un medio de pago: su nombre, lo que dejó este mes y, debajo, cuánto entró y
/// cuánto salió por él.
class MethodFlowTile extends StatelessWidget {
  const MethodFlowTile({super.key, required this.flow, required this.hidden});

  final MethodFlow flow;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mask = AnimatedNumberText.mask;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
      child: LabelAmountRow(
        crossAxisAlignment: CrossAxisAlignment.start,
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatDisplayText(flow.name), style: textTheme.titleSmall),
            Text(
              hidden
                  ? 'Entró $mask · Salió $mask'
                  : 'Entró ${formatCents(flow.incomeCents)} · '
                        'Salió ${formatCents(flow.expenseCents)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        amount: Text(
          hidden ? mask : formatCentsSigned(flow.netCents),
          maxLines: 1,
          softWrap: false,
          style: textTheme.titleSmall?.copyWith(
            color: flow.netCents >= 0 ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
