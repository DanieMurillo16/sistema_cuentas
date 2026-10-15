import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/cop_currency_input_formatter.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_form_rules.dart';

/// El monto, grande y arriba: `$` del color del tipo (verde ingreso, rojo gasto)
/// y el valor con puntos de miles mientras se escribe.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.type,
    required this.enabled,
    this.focusNode,
  });

  final TextEditingController controller;
  final MovementType type;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final color = type.isIncome ? AppColors.income : AppColors.expense;
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.displaySmall;
    final caption = type.isIncome ? 'Valor del ingreso' : 'Valor del gasto';
    // El título es fijo y el `$` viaja pegado al valor: todo queda centrado y
    // nada se mueve ni cambia de lugar cuando se empieza a escribir.
    return Column(
      children: [
        // El lector ya dice el título en el campo: aquí no se repite.
        ExcludeSemantics(
          child: Text(
            caption,
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: IntrinsicWidth(
            child: Semantics(
              label: caption,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                readOnly: !enabled,
                textAlign: TextAlign.center,
                style: style,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  const CopCurrencyInputFormatter(),
                  LengthLimitingTextInputFormatter(
                    MovementFormRules.maxAmountChars,
                  ),
                ],
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0',
                  hintStyle: style?.copyWith(color: AppColors.muted),
                  prefix: Text('\$ ', style: style?.copyWith(color: color)),
                ),
                validator: MovementFormRules.validateAmount,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
