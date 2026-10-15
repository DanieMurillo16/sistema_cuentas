import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

/// «Me pagan» (ingreso) o «Yo pago» (gasto).
class RecurringTypeToggle extends StatelessWidget {
  const RecurringTypeToggle({
    super.key,
    required this.type,
    required this.onChanged,
    required this.enabled,
  });

  final MovementType type;
  final ValueChanged<MovementType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppToggle<MovementType>(
      selected: type,
      enabled: enabled,
      onSelected: onChanged,
      options: const [
        AppToggleOption(
          value: MovementType.income,
          label: 'Me pagan',
          icon: Icons.south_west_rounded,
          color: AppColors.success,
        ),
        AppToggleOption(
          value: MovementType.expense,
          label: 'Yo pago',
          icon: Icons.north_east_rounded,
          color: AppColors.error,
        ),
      ],
    );
  }
}
