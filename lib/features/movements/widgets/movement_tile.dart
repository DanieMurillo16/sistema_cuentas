import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile_row.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_to_delete.dart';

/// Una fila del historial: icono, descripción, categoría · medio y monto.
/// Las filas de un mismo día se ven como una sola tarjeta: solo la primera y
/// la última tienen las esquinas redondeadas.
class MovementTile extends StatelessWidget {
  const MovementTile({
    super.key,
    required this.movement,
    required this.position,
    required this.hidden,
    this.onTap,
    this.onConfirmCancel,
  });

  final Movement movement;
  final RowPosition position;
  final bool hidden;
  final VoidCallback? onTap;

  /// Si no es `null`, la fila se puede deslizar hacia la izquierda para
  /// eliminarla: pregunta y devuelve `true` si quedó eliminada.
  final Future<bool> Function()? onConfirmCancel;

  BorderRadius get _radius {
    const round = Radius.circular(DesignTokens.radiusLg);
    final top = position == RowPosition.first || position == RowPosition.only;
    final bottom = position == RowPosition.last || position == RowPosition.only;
    return BorderRadius.vertical(
      top: top ? round : Radius.zero,
      bottom: bottom ? round : Radius.zero,
    );
  }

  String get _semanticLabel =>
      '${movement.isIncome ? 'Ingreso' : 'Gasto'}, ${movement.description}, '
      '${movement.contact == null ? '' : '${movement.contact}, '}'
      '${movement.category}, ${movement.method}, '
      '${formatCentsSigned(movement.signedCents)} pesos'
      '${movement.createdAt == null ? '' : ', a las ${formatClock(movement.createdAt!)}'}';

  @override
  Widget build(BuildContext context) {
    final showDivider =
        position == RowPosition.middle || position == RowPosition.last;
    return Semantics(
      // El tipo se entiende por la palabra, no solo por el color y la flecha;
      // con el ojo cerrado el lector no dice el monto.
      label: hidden
          ? '${movement.isIncome ? 'Ingreso' : 'Gasto'}, '
                '${movement.description}, monto oculto'
          : _semanticLabel,
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      // Quien no ve deslizar tiene la misma acción en el menú del lector.
      customSemanticsActions: onConfirmCancel == null
          ? null
          : {
              const CustomSemanticsAction(label: 'Eliminar'): () =>
                  onConfirmCancel!(),
            },
      child: ClipRRect(
        borderRadius: _radius,
        child: SwipeToDelete(
          itemKey: 'movement-${movement.id}',
          onConfirm: onConfirmCancel,
          // Material (no ColoredBox): la salpicadura del toque se ve y viaja
          // con la fila al deslizarla.
          child: Material(
            color: AppColors.surface,
            child: Column(
              children: [
                if (showDivider) const Divider(height: 1),
                InkWell(
                  onTap: onTap,
                  child: MovementTileRow(movement: movement, hidden: hidden),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
