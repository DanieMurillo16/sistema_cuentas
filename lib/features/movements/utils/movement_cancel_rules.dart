import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';

/// Reglas puras de eliminar (anular) un movimiento.
abstract final class MovementCancelRules {
  /// El servidor pide un motivo para anular (3 a 255 letras); la app no lo
  /// pregunta: manda este y queda en el historial del movimiento anulado.
  static const reason = 'Eliminado desde la app';

  static String title(Movement movement) =>
      movement.isIncome ? 'Eliminar ingreso' : 'Eliminar gasto';

  /// Lo que se va a quitar, para no equivocarse de fila.
  static String subtitle(Movement movement) =>
      '${formatDisplayText(movement.description)} · '
      '${formatCentsSigned(movement.signedCents)}';
}
