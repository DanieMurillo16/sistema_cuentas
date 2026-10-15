import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

/// Lo que el formulario manda para registrar un movimiento suelto.
class MovementDraft {
  const MovementDraft({
    required this.type,
    required this.amountPesos,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.methodId,
    this.note,
  });

  final MovementType type;

  /// Pesos completos (el formulario no admite centavos).
  final int amountPesos;
  final DateTime date;
  final String description;
  final int categoryId;
  final int methodId;
  final String? note;

  /// Cuerpo de `movimientos/registrar.php`; el dinero va como texto.
  Map<String, dynamic> toJson() => {
    'tipo': type.apiValue,
    'valor': amountPesos.toString(),
    'fecha': apiDate(date),
    'descripcion': description,
    'id_categoria': categoryId,
    'id_medio': methodId,
    if (note != null) 'nota': note,
  };
}
