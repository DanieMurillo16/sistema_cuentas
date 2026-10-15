import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/payment_method_field.dart';
import 'package:sistema_cuentas/features/recurring/widgets/finish_note_field.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/widgets/app_collapse.dart';
import 'package:sistema_cuentas/shared/widgets/app_date_field.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';

/// Los campos del cierre: fecha y capital en pareja, el motivo (obligatorio) y,
/// solo si hay capital, el medio de pago por el que se movió.
class FinishRecurringFields extends StatelessWidget {
  const FinishRecurringFields({
    super.key,
    required this.payment,
    required this.note,
    required this.capital,
    required this.endDate,
    required this.method,
    required this.onDateChanged,
    required this.onMethodChanged,
    required this.readOnly,
  });

  final RecurringPayment payment;
  final TextEditingController note;
  final TextEditingController capital;
  final DateTime endDate;
  final PaymentMethod? method;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<PaymentMethod?> onMethodChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormPair(
          minWidth: DesignTokens.formDatePairMinWidth,
          first: AppDateField(
            label: 'Cierre',
            date: endDate,
            firstDate: payment.startDate,
            lastDate: RecurringRules.lastEndDate(
              payment.startDate,
              DateTime.now(),
            ),
            enabled: !readOnly,
            onChanged: onDateChanged,
          ),
          second: TextFormField(
            controller: capital,
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              const CopCurrencyInputFormatter(),
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: InputDecoration(
              labelText: 'Capital (opcional)',
              helperText: payment.isIncome
                  ? 'Lo que te devolvieron'
                  : 'Lo que pagaste',
              prefixText: '\$ ',
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: capital,
          builder: (context, value, _) => AppCollapse(
            visible: RecurringRules.hasCapital(value.text),
            child: Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
              child: PaymentMethodField(
                label: 'Medio de pago del capital',
                value: method,
                onChanged: onMethodChanged,
                validator: (selected) => RecurringRules.validateCapitalMethod(
                  capital.text,
                  selected,
                ),
              ),
            ),
          ),
        ),
        FinishNoteField(controller: note, readOnly: readOnly),
      ],
    );
  }
}
