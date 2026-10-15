import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// La plata real que entró o salió (un pago, un abono o un movimiento suelto).
class Movement {
  const Movement({
    required this.id,
    required this.type,
    required this.valueCents,
    required this.date,
    required this.description,
    required this.categoryId,
    required this.category,
    required this.methodId,
    required this.method,
    required this.isCapital,
    required this.fromRecurring,
    required this.cancelled,
    this.contact,
    this.note,
    this.cancelReason,
    this.createdAt,
  });

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
    id: asInt(json['id_movimiento']),
    type: MovementType.fromApi(json['tipo']),
    valueCents: moneyToCents(json['valor']),
    date: parseApiDate(json['fecha'] as String),
    description: json['descripcion'] as String? ?? '',
    categoryId: asInt(json['id_categoria']),
    category: json['categoria'] as String? ?? '',
    methodId: asInt(json['id_medio']),
    method: json['medio'] as String? ?? '',
    isCapital: json['es_capital'] == true,
    fromRecurring:
        json['origen'] == 'RECURRENTE' || json['id_vencimiento'] != null,
    cancelled: json['anulado'] == true,
    contact: asOptionalText(json['contacto']),
    note: asOptionalText(json['nota']),
    cancelReason: asOptionalText(json['motivo_anulacion']),
    createdAt: parseApiDateTime(json['creado_en']),
  );

  final int id;
  final MovementType type;

  /// Importe en centavos (el servidor manda texto; ver `moneyToCents`).
  final int valueCents;
  final DateTime date;
  final String description;
  final int categoryId;
  final String category;
  final int methodId;
  final String method;
  final bool isCapital;
  final bool fromRecurring;
  final bool cancelled;
  final String? contact;
  final String? note;
  final String? cancelReason;

  /// Cuándo se registró (fecha y hora de Colombia). `null` si el servidor no la
  /// manda: la fila simplemente no muestra la hora.
  final DateTime? createdAt;

  bool get isIncome => type.isIncome;

  /// Lo que suma al flujo: positivo si entra, negativo si sale.
  int get signedCents => isIncome ? valueCents : -valueCents;
}
