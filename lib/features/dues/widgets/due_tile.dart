import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_tile_body.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_card.dart';

/// Una fila de «Este mes»: con quién es, de qué, cuándo, cuánto falta y su
/// estado. Si se puede pagar, el botón queda ahí mismo (Cobrar / Pagar). Si se
/// puede eliminar, se desliza a la izquierda.
class DueTile extends StatelessWidget {
  const DueTile({
    super.key,
    required this.due,
    required this.hidden,
    required this.onPay,
    this.onConfirmDelete,
  });

  final Due due;
  final bool hidden;
  final VoidCallback onPay;

  /// Si no es `null`, la fila se desliza a la izquierda para eliminar el
  /// acuerdo: pregunta y devuelve `true` si quedó eliminado.
  final Future<bool> Function()? onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return SwipeCard(
      itemKey: 'due-${due.id}',
      onConfirm: onConfirmDelete,
      child: DueTileBody(due: due, hidden: hidden, onPay: onPay),
    );
  }
}
