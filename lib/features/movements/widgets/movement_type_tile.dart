import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_icon.dart';

/// Opción grande de la hoja «+»: registrar un gasto o un ingreso.
class MovementTypeTile extends StatelessWidget {
  const MovementTypeTile({super.key, required this.type, required this.onTap});

  final MovementType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MovementIcon(type: type),
              const SizedBox(height: DesignTokens.spaceMd),
              Text(
                type.isIncome ? 'Ingreso' : 'Gasto',
                style: textTheme.titleMedium,
              ),
              Text(
                type.isIncome ? 'Dinero que entra' : 'Dinero que sale',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
