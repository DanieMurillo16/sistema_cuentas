import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_amount_row.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';

/// Lo esencial del mes en tres líneas: lo que entró, lo que salió y lo que quedó.
class SummaryTotalsCard extends StatelessWidget {
  const SummaryTotalsCard({
    super.key,
    required this.totals,
    required this.hidden,
  });

  final SummaryTotals totals;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return SummarySectionCard(
      title: 'El mes',
      subtitle: totals.movementCount == 1
          ? '1 movimiento'
          : '${totals.movementCount} movimientos',
      child: Column(
        children: [
          SummaryAmountRow(
            label: 'Ingresos',
            amount: formatCents(totals.incomeTotalCents),
            hidden: hidden,
            color: AppColors.income,
          ),
          SummaryAmountRow(
            label: 'Gastos',
            amount: formatCents(totals.expenseTotalCents),
            hidden: hidden,
            color: AppColors.expense,
          ),
          const Divider(),
          SummaryAmountRow(
            label: 'Balance',
            amount: formatCentsSigned(totals.netFlowCents),
            hidden: hidden,
            emphasized: true,
            color: totals.netFlowCents >= 0
                ? AppColors.income
                : AppColors.expense,
          ),
        ],
      ),
    );
  }
}
