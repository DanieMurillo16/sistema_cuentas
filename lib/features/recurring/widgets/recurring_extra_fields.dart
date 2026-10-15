import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';

/// Capital (opcional, para préstamos): campo de fila completa.
class RecurringExtraFields extends StatelessWidget {
  const RecurringExtraFields({
    super.key,
    required this.capital,
    required this.readOnly,
  });

  final TextEditingController capital;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: capital,
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [
            const CopCurrencyInputFormatter(),
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: const InputDecoration(
            labelText: 'Capital (opcional)',
            helperText: 'Si es un préstamo: lo prestado o recibido',
            prefixText: '\$ ',
          ),
        ),
      ],
    );
  }
}
