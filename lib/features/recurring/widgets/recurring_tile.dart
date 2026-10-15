import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_tile_body.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_card.dart';

/// Un acuerdo en la lista: con quién es, de qué, su día y su valor. Al tocarla
/// se abre su detalle con el historial; si se puede eliminar, se desliza a la
/// izquierda.
class RecurringTile extends StatelessWidget {
  const RecurringTile({
    super.key,
    required this.payment,
    required this.hidden,
    required this.onTap,
    this.onConfirmDelete,
  });

  final RecurringPayment payment;
  final bool hidden;
  final VoidCallback onTap;

  /// Si no es `null`, la fila se desliza a la izquierda para eliminarla:
  /// pregunta y devuelve `true` si quedó eliminada.
  final Future<bool> Function()? onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return SwipeCard(
      itemKey: 'recurring-${payment.id}',
      onConfirm: onConfirmDelete,
      child: RecurringTileBody(payment: payment, hidden: hidden, onTap: onTap),
    );
  }
}
