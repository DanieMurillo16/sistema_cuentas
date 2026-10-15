import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/widgets/amount_field.dart';
import 'package:sistema_cuentas/features/movements/widgets/date_pill.dart';

/// Lo primero del formulario: el monto grande y la fecha debajo, en su píldora.
class MovementAmountSection extends StatelessWidget {
  const MovementAmountSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.type,
    required this.date,
    required this.onDateChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final MovementType type;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AmountField(
          controller: controller,
          focusNode: focusNode,
          type: type,
          enabled: enabled,
        ),
        DatePill(date: date, enabled: enabled, onChanged: onDateChanged),
      ],
    );
  }
}
