import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_status_chip.dart';

/// Pie de la fila de un vencimiento: su estado y, si se puede, Cobrar / Pagar.
class DueTileActions extends StatelessWidget {
  const DueTileActions({super.key, required this.due, required this.onPay});

  final Due due;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: DueStatusChip(info: DuesRules.statusInfo(due)),
          ),
        ),
        if (due.canPay)
          Semantics(
            // El lector dice a qué vencimiento corresponde, no solo «Pagar».
            label: '${DuesRules.actionLabel(due)} ${due.description}',
            button: true,
            excludeSemantics: true,
            child: FilledButton.tonal(
              onPressed: onPay,
              style: FilledButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(DuesRules.actionLabel(due)),
            ),
          ),
      ],
    );
  }
}
