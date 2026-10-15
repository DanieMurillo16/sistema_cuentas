import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

/// Un pago o abono de un vencimiento. La descripción y la categoría las toma
/// el servidor del acuerdo; el medio de pago siempre es obligatorio.
class DuePaymentDraft {
  const DuePaymentDraft({
    required this.dueId,
    required this.recurringId,
    required this.type,
    required this.amountPesos,
    required this.date,
    required this.methodId,
    this.note,
  });

  final int dueId;

  /// Acuerdo al que pertenece (no se envía: sirve para refrescar su detalle).
  final int recurringId;
  final MovementType type;
  final int amountPesos;
  final DateTime date;
  final int methodId;
  final String? note;

  /// Cuerpo de `movimientos/registrar.php`; el dinero va como texto.
  Map<String, dynamic> toJson() => {
    'tipo': type.apiValue,
    'valor': amountPesos.toString(),
    'fecha': apiDate(date),
    'id_medio': methodId,
    'id_vencimiento': dueId,
    if (note != null) 'nota': note,
  };
}
