import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/payment_method_field.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_date_field.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';

/// Los campos del diálogo de pago: valor y fecha en pareja, medio de pago y
/// nota. Valor corto con fecha corta: comparten fila desde 240 px.
class PayDueFields extends StatelessWidget {
  const PayDueFields({
    super.key,
    required this.due,
    required this.amount,
    required this.note,
    required this.date,
    required this.method,
    required this.onDateChanged,
    required this.onMethodChanged,
    required this.readOnly,
  });

  final Due due;
  final TextEditingController amount;
  final TextEditingController note;
  final DateTime date;
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
          first: TextFormField(
            controller: amount,
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              const CopCurrencyInputFormatter(),
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: InputDecoration(labelText: 'Valor', prefixText: '\$ '),
            validator: (text) => DuesRules.validateAmount(text, due),
          ),
          second: AppDateField(
            label: 'Fecha',
            date: date,
            firstDate: DateTime(due.period.year - 1),
            lastDate: dateOnly(DateTime.now()),
            enabled: !readOnly,
            onChanged: onDateChanged,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        PaymentMethodField(
          value: method,
          onChanged: onMethodChanged,
          validator: DuesRules.validatePaymentMethod,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        TextFormField(
          controller: note,
          readOnly: readOnly,
          maxLines: 2,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(DuesRules.noteMaxLength),
          ],
          decoration: const InputDecoration(labelText: 'Nota (opcional)'),
        ),
      ],
    );
  }
}
