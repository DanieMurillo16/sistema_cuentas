import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';

/// Lo que el formulario manda para crear un pago recurrente.
class RecurringDraft {
  const RecurringDraft({
    required this.type,
    required this.description,
    required this.valuePesos,
    required this.dayOfMonth,
    required this.everyMonths,
    required this.startDate,
    required this.categoryId,
    this.contactId,
    this.capitalPesos,
    this.note,
  });

  final MovementType type;
  final String description;
  final int valuePesos;
  final int dayOfMonth;
  final int everyMonths;
  final DateTime startDate;
  final int categoryId;
  final int? contactId;
  final int? capitalPesos;
  final String? note;

  /// Cuerpo de `pagos_recurrentes/crear.php`; el dinero va como texto.
  Map<String, dynamic> toJson() => {
    'tipo': type.apiValue,
    'descripcion': description,
    'valor': valuePesos.toString(),
    'dia_pago': dayOfMonth,
    'cada_meses': everyMonths,
    'fecha_inicio': apiDate(startDate),
    'id_categoria': categoryId,
    if (contactId != null) 'id_contacto': contactId,
    if (capitalPesos != null) 'capital': capitalPesos.toString(),
    if (note != null) 'nota': note,
  };
}
