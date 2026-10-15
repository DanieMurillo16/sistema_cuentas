import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/payment_method_field.dart';
import 'package:sistema_cuentas/features/initial_balance/utils/initial_balance_rules.dart';

/// Un solo valor y el medio de pago donde está.
class InitialBalanceSingleFields extends StatelessWidget {
  const InitialBalanceSingleFields({
    super.key,
    required this.controller,
    required this.method,
    required this.readOnly,
    required this.onChanged,
    required this.onMethodChanged,
  });

  final TextEditingController controller;
  final PaymentMethod? method;
  final bool readOnly;
  final VoidCallback onChanged;
  final ValueChanged<PaymentMethod?> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [
            const CopCurrencyInputFormatter(),
            LengthLimitingTextInputFormatter(13),
          ],
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Valor que tienes hoy',
            prefixText: '\$ ',
          ),
          validator: InitialBalanceRules.validateAmount,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        PaymentMethodField(
          value: method,
          onChanged: onMethodChanged,
          validator: InitialBalanceRules.validateMethod,
          label: 'En qué medio lo tienes',
        ),
      ],
    );
  }
}
