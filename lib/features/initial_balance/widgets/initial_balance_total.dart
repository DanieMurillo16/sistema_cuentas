import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/label_amount_row.dart';

/// El total que se va a registrar, para comprobar la suma antes de guardar.
class InitialBalanceTotal extends StatelessWidget {
  const InitialBalanceTotal({super.key, required this.pesos});

  final int pesos;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LabelAmountRow(
      label: Text('Total', style: textTheme.titleSmall),
      // Con valores enormes el total se encoge en vez de desbordar.
      amount: Text(
        formatCop(pesos),
        maxLines: 1,
        softWrap: false,
        style: textTheme.titleMedium?.copyWith(color: AppColors.income),
      ),
    );
  }
}
