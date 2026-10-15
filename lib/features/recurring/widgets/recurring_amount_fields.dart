import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';

/// Valor y día de pago: dos campos cortos que comparten fila.
class RecurringAmountFields extends StatelessWidget {
  const RecurringAmountFields({
    super.key,
    required this.value,
    required this.day,
    required this.readOnly,
  });

  final TextEditingController value;
  final TextEditingController day;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return AppFormPair(
      minWidth: DesignTokens.formShortPairMinWidth,
      first: TextFormField(
        controller: value,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          const CopCurrencyInputFormatter(),
          LengthLimitingTextInputFormatter(13),
        ],
        decoration: const InputDecoration(
          labelText: 'Valor',
          prefixText: '\$ ',
        ),
        validator: RecurringRules.validateValue,
      ),
      second: TextFormField(
        controller: day,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: const InputDecoration(labelText: 'Día de pago'),
        validator: RecurringRules.validateDay,
      ),
    );
  }
}
