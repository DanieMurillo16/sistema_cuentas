import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_status_chip.dart';
import 'package:sistema_cuentas/features/recurring/models/due_history_item.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Un mes del historial: cuánto tocaba, cuánto se movió y en qué estado quedó.
class DueHistoryTile extends StatelessWidget {
  const DueHistoryTile({
    super.key,
    required this.item,
    required this.isIncome,
    required this.hidden,
  });

  final DueHistoryItem item;
  final bool isIncome;
  final bool hidden;

  String _money(int cents) =>
      hidden ? AnimatedNumberText.mask : formatCents(cents);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final info = DuesRules.statusInfoFor(
      status: item.status,
      overdue: item.overdue,
      daysToDue: item.daysToDue,
      isIncome: isIncome,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatMonthName(item.period), style: textTheme.titleSmall),
            Text(
              '${_money(item.paidCents)} de ${_money(item.expectedCents)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            DueStatusChip(info: info),
          ],
        ),
      ),
    );
  }
}
