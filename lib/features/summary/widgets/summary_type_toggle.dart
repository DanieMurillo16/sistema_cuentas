import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

/// Ingresos o Gastos en una tarjeta del resumen: verde y rojo, como en el resto
/// de la app. [expenseFirst] pone Gastos a la izquierda.
class SummaryTypeToggle extends StatelessWidget {
  const SummaryTypeToggle({
    super.key,
    required this.selected,
    required this.onSelected,
    this.expenseFirst = false,
  });

  final MovementType selected;
  final ValueChanged<MovementType> onSelected;
  final bool expenseFirst;

  @override
  Widget build(BuildContext context) {
    const income = AppToggleOption(
      value: MovementType.income,
      label: 'Ingresos',
      color: AppColors.success,
    );
    const expense = AppToggleOption(
      value: MovementType.expense,
      label: 'Gastos',
      color: AppColors.error,
    );
    return AppToggle<MovementType>(
      compact: true,
      selected: selected,
      onSelected: onSelected,
      options: expenseFirst ? const [expense, income] : const [income, expense],
    );
  }
}
