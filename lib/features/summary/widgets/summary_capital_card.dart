import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_amount_row.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';

/// El capital que se recuperó o se entregó, aparte de lo operativo.
class SummaryCapitalCard extends StatelessWidget {
  const SummaryCapitalCard({
    super.key,
    required this.totals,
    required this.hidden,
  });

  final SummaryTotals totals;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return SummarySectionCard(
      title: 'Capital',
      subtitle: 'Aparte de ingresos y gastos operativos',
      child: Column(
        children: [
          SummaryAmountRow(
            label: 'Recuperado',
            amount: formatCents(totals.capitalRecoveredCents),
            hidden: hidden,
            color: AppColors.income,
          ),
          SummaryAmountRow(
            label: 'Entregado',
            amount: formatCents(totals.capitalDeliveredCents),
            hidden: hidden,
            color: AppColors.expense,
          ),
        ],
      ),
    );
  }
}
