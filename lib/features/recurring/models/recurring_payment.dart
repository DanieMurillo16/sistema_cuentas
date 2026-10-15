import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// El acuerdo que se repite: «Oscar me paga 180.000 el día 7», «Netflix 45.000
/// el día 12». De él salen los vencimientos de cada mes.
class RecurringPayment {
  const RecurringPayment({
    required this.id,
    required this.type,
    required this.description,
    required this.valueCents,
    required this.dayOfMonth,
    required this.everyMonths,
    required this.startDate,
    required this.categoryId,
    required this.category,
    required this.active,
    this.contactId,
    this.contact,
    this.capitalCents,
    this.note,
    this.endDate,
    this.closingNote,
    this.totalPaidCents,
    this.nextDueDate,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) {
    final capital = asOptionalText(json['capital']);
    final totalPaid = asOptionalText(json['total_pagado']);
    final end = asOptionalText(json['fecha_fin']);
    final next = asOptionalText(json['proximo_vencimiento']);
    return RecurringPayment(
      id: asInt(json['id_pago_recurrente']),
      type: MovementType.fromApi(json['tipo']),
      description: json['descripcion'] as String? ?? '',
      valueCents: moneyToCents(json['valor']),
      dayOfMonth: asInt(json['dia_pago']),
      everyMonths: asInt(json['cada_meses']),
      startDate: parseApiDate(json['fecha_inicio'] as String),
      categoryId: asInt(json['id_categoria']),
      category: json['categoria'] as String? ?? '',
      active: json['estado'] == 'ACTIVO',
      contactId: json['id_contacto'] == null
          ? null
          : asInt(json['id_contacto']),
      contact: asOptionalText(json['contacto']),
      capitalCents: capital == null ? null : moneyToCents(capital),
      note: asOptionalText(json['nota']),
      endDate: end == null ? null : parseApiDate(end),
      closingNote: asOptionalText(json['nota_cierre']),
      totalPaidCents: totalPaid == null ? null : moneyToCents(totalPaid),
      nextDueDate: next == null ? null : parseApiDate(next),
    );
  }

  final int id;
  final MovementType type;
  final String description;
  final int valueCents;
  final int dayOfMonth;
  final int everyMonths;
  final DateTime startDate;
  final int categoryId;
  final String category;
  final bool active;
  final int? contactId;
  final String? contact;

  /// Capital de un préstamo (lo que se prestó o se recibió), si aplica.
  final int? capitalCents;
  final String? note;
  final DateTime? endDate;
  final String? closingNote;

  /// Solo viene en el listado.
  final int? totalPaidCents;

  /// Primer vencimiento que aún no está pagado (solo en el listado).
  final DateTime? nextDueDate;

  bool get isIncome => type.isIncome;
}
