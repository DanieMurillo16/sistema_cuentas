import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';

/// La primera línea de una fila del historial: con quién, si el movimiento
/// tiene contacto («Santo cafe»), y si no, la descripción. La descripción de un
/// pago recurrente («Desarrollo mensual») repite lo que ya dice la categoría de
/// abajo, por eso no se muestra junto al contacto.
class MovementTileTitle extends StatelessWidget {
  const MovementTileTitle({super.key, required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatDisplayText(movement.contact ?? movement.description),
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}
