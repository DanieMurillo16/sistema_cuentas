import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_icon.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/features/recurring/widgets/detail_row.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// La ficha de un pago recurrente: quién, cuánto, cada cuándo y su estado.
class RecurringSummaryCard extends StatelessWidget {
  const RecurringSummaryCard({
    super.key,
    required this.payment,
    required this.hidden,
  });

  final RecurringPayment payment;
  final bool hidden;

  String _money(int cents) =>
      hidden ? AnimatedNumberText.mask : formatCents(cents);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final end = payment.endDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MovementIcon(
                  type: payment.type,
                  categoryId: payment.categoryId,
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Text(
                    RecurringRules.title(payment),
                    style: textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            DetailRow(label: 'Valor', value: _money(payment.valueCents)),
            DetailRow(
              label: 'Se repite',
              value: RecurringRules.scheduleLabel(payment),
            ),
            if (payment.contact != null)
              DetailRow(
                label: payment.isIncome ? 'Me paga' : 'Le pago a',
                value: formatDisplayText(payment.contact!),
              ),
            DetailRow(
              label: 'Categoría',
              value: formatDisplayText(payment.category),
            ),
            if (payment.totalPaidCents != null)
              DetailRow(
                label: payment.isIncome ? 'Total cobrado' : 'Total pagado',
                value: _money(payment.totalPaidCents!),
              ),
            if (payment.capitalCents != null)
              DetailRow(label: 'Capital', value: _money(payment.capitalCents!)),
            DetailRow(label: 'Desde', value: formatDate(payment.startDate)),
            if (payment.note != null)
              DetailRow(label: 'Nota', value: payment.note!),
            if (!payment.active && end != null) ...[
              const Divider(),
              DetailRow(label: 'Finalizado', value: formatDate(end)),
              if (payment.closingNote != null)
                DetailRow(label: 'Motivo', value: payment.closingNote!),
            ],
          ],
        ),
      ),
    );
  }
}
