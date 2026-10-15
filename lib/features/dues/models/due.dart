import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Estado de un vencimiento (lo deriva el servidor).
enum DueStatus {
  pending('PENDIENTE'),
  partial('PARCIAL'),
  paid('PAGADO'),
  cancelled('ANULADO');

  const DueStatus(this.apiValue);

  final String apiValue;

  static DueStatus fromApi(Object? raw) => values.firstWhere(
    (status) => status.apiValue == raw,
    orElse: () => throw FormatException('Estado de vencimiento inválido: $raw'),
  );
}

/// Lo que toca pagar o cobrar de un pago recurrente en un mes concreto.
class Due {
  const Due({
    required this.id,
    required this.recurringId,
    required this.type,
    required this.description,
    required this.period,
    required this.dueDate,
    required this.expectedCents,
    required this.paidCents,
    required this.balanceCents,
    required this.status,
    required this.overdue,
    required this.daysToDue,
    required this.categoryId,
    required this.category,
    this.contactId,
    this.contact,
  });

  factory Due.fromJson(Map<String, dynamic> json) => Due(
    id: asInt(json['id_vencimiento']),
    recurringId: asInt(json['id_pago_recurrente']),
    type: MovementType.fromApi(json['tipo']),
    description: json['descripcion'] as String? ?? '',
    period: parseApiDate(json['periodo'] as String),
    dueDate: parseApiDate(json['fecha_vencimiento'] as String),
    expectedCents: moneyToCents(json['valor_esperado']),
    paidCents: moneyToCents(json['pagado']),
    balanceCents: moneyToCents(json['saldo']),
    status: DueStatus.fromApi(json['estado']),
    overdue: json['vencido'] == true,
    daysToDue: asInt(json['dias_para_vencer']),
    categoryId: asInt(json['id_categoria']),
    category: json['categoria'] as String? ?? '',
    contactId: json['id_contacto'] == null ? null : asInt(json['id_contacto']),
    contact: asOptionalText(json['contacto']),
  );

  final int id;
  final int recurringId;
  final MovementType type;
  final String description;
  final DateTime period;
  final DateTime dueDate;
  final int expectedCents;
  final int paidCents;
  final int balanceCents;
  final DueStatus status;
  final bool overdue;

  /// Negativo = ya venció.
  final int daysToDue;
  final int categoryId;
  final String category;
  final int? contactId;
  final String? contact;

  bool get isIncome => type.isIncome;

  /// Se puede registrar un pago o abono: hay saldo y no está cerrado.
  bool get canPay =>
      balanceCents > 0 &&
      (status == DueStatus.pending || status == DueStatus.partial);
}
