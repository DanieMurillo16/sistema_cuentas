import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_amount_text.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_icon.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile_detail.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile_title.dart';

/// El contenido compacto de una fila del historial, en dos líneas: arriba de qué
/// es y el monto en la esquina; abajo categoría · medio y la hora en la esquina.
/// Así lo de la izquierda usa casi todo el ancho.
class MovementTileRow extends StatelessWidget {
  const MovementTileRow({
    super.key,
    required this.movement,
    required this.hidden,
  });

  final Movement movement;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.tileVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MovementIcon(type: movement.type, categoryId: movement.categoryId),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // El monto no es flexible: mide lo suyo (hasta la mitad de la fila)
                // y el texto se queda con todo lo demás.
                LayoutBuilder(
                  builder: (context, constraints) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: MovementTileTitle(movement: movement)),
                      const SizedBox(width: DesignTokens.spaceSm),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.5,
                        ),
                        child: MovementAmountText(
                          flexible: false,
                          text: formatCentsSigned(movement.signedCents),
                          income: movement.isIncome,
                          hidden: hidden,
                        ),
                      ),
                    ],
                  ),
                ),
                MovementTileDetail(movement: movement),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
