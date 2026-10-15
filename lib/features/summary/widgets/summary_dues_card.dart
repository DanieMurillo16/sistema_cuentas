import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_amount_row.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Lo que falta del mes: por cobrar y por pagar, con la parte vencida.
class SummaryDuesCard extends StatelessWidget {
  const SummaryDuesCard({
    super.key,
    required this.summary,
    required this.hidden,
  });

  final MonthSummary summary;
  final bool hidden;

  String _overdue(int cents, int count) => hidden
      ? 'Vencido ${AnimatedNumberText.mask}'
      : 'Vencido ${formatCents(cents)} ($count)';

  @override
  Widget build(BuildContext context) {
    final income = summary.duesFor(MovementType.income);
    final expense = summary.duesFor(MovementType.expense);
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.expense);
    return SummarySectionCard(
      title: 'Pendiente del mes',
      subtitle: 'Lo que falta por cobrar y por pagar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryAmountRow(
            label: 'Por cobrar',
            amount: formatCents(income.balanceCents),
            hidden: hidden,
            color: AppColors.income,
          ),
          if (income.overdueCount > 0)
            Text(
              _overdue(income.overdueBalanceCents, income.overdueCount),
              style: small,
            ),
          const SizedBox(height: DesignTokens.spaceSm),
          SummaryAmountRow(
            label: 'Por pagar',
            amount: formatCents(expense.balanceCents),
            hidden: hidden,
            color: AppColors.expense,
          ),
          if (expense.overdueCount > 0)
            Text(
              _overdue(expense.overdueBalanceCents, expense.overdueCount),
              style: small,
            ),
        ],
      ),
    );
  }
}
