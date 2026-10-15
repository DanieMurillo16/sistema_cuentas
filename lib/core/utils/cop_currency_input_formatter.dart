import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';

class CopCurrencyInputFormatter extends TextInputFormatter {
  const CopCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = parseCopInput(newValue.text);
    if (value == null) return TextEditingValue.empty;
    final text = formatCopInput(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
