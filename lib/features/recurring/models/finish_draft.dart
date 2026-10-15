import 'package:sistema_cuentas/core/utils/date_formatter.dart';

/// Lo que se manda para finalizar un pago recurrente (irreversible).
class FinishDraft {
  const FinishDraft({
    required this.recurringId,
    required this.endDate,
    required this.closingNote,
    this.capitalPesos,
    this.methodId,
  });

  final int recurringId;
  final DateTime endDate;
  final String closingNote;

  /// Capital devuelto (ingreso) o pagado (gasto) en el mismo acto.
  final int? capitalPesos;

  /// Obligatorio si hay capital.
  final int? methodId;

  Map<String, dynamic> toJson() => {
    'id_pago_recurrente': recurringId,
    'fecha_fin': apiDate(endDate),
    'nota_cierre': closingNote,
    if (capitalPesos != null) 'valor_capital': capitalPesos.toString(),
    if (capitalPesos != null && methodId != null) 'id_medio': methodId,
  };
}
