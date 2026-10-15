import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/initial_balance/utils/initial_balance_rules.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';

/// Un campo de valor por cada medio de pago (Nequi, Bancolombia, efectivo…).
/// Lo que se deja vacío no se registra.
class InitialBalanceMethodFields extends StatelessWidget {
  const InitialBalanceMethodFields({
    super.key,
    required this.methods,
    required this.controllers,
    required this.readOnly,
    required this.onChanged,
  });

  final List<PaymentMethod> methods;
  final Map<int, TextEditingController> controllers;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    // De dos en dos: son campos cortos (un valor), así no hay una fila por medio.
    final rows = <List<PaymentMethod>>[
      for (var i = 0; i < methods.length; i += 2)
        methods.sublist(i, i + 2 > methods.length ? methods.length : i + 2),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const SizedBox(height: DesignTokens.spaceMd),
          if (row.length == 2)
            AppFormPair(
              minWidth: DesignTokens.formShortPairMinWidth,
              first: _MethodAmountField(
                method: row[0],
                controller: controllers[row[0].id],
                readOnly: readOnly,
                onChanged: onChanged,
              ),
              second: _MethodAmountField(
                method: row[1],
                controller: controllers[row[1].id],
                readOnly: readOnly,
                onChanged: onChanged,
              ),
            )
          else
            _MethodAmountField(
              method: row[0],
              controller: controllers[row[0].id],
              readOnly: readOnly,
              onChanged: onChanged,
            ),
        ],
      ],
    );
  }
}

class _MethodAmountField extends StatelessWidget {
  const _MethodAmountField({
    required this.method,
    required this.controller,
    required this.readOnly,
    required this.onChanged,
  });

  final PaymentMethod method;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('initial-balance-${method.id}'),
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      inputFormatters: [
        const CopCurrencyInputFormatter(),
        LengthLimitingTextInputFormatter(13),
      ],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: formatDisplayText(method.name),
        prefixText: '\$ ',
      ),
      validator: InitialBalanceRules.validateOptionalAmount,
    );
  }
}
