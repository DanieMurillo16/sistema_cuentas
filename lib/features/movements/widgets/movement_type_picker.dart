import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_type_tile.dart';

/// Las dos opciones grandes de la hoja «+»: Ingreso y Gasto.
class MovementTypePicker extends StatelessWidget {
  const MovementTypePicker({super.key, required this.onSelected});

  final ValueChanged<MovementType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
        DesignTokens.spaceMd,
        DesignTokens.spaceLg,
      ),
      // IntrinsicHeight: las dos opciones miden igual y la fila no tiene
      // altura infinita dentro del scroll.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final type in MovementType.values) ...[
              Expanded(
                child: MovementTypeTile(
                  type: type,
                  onTap: () => onSelected(type),
                ),
              ),
              if (type != MovementType.values.last)
                const SizedBox(width: DesignTokens.spaceMd),
            ],
          ],
        ),
      ),
    );
  }
}
