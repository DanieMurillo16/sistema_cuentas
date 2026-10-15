import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';

/// Un mes del historial de un pago recurrente.
class DueHistoryItem {
  const DueHistoryItem({
    required this.id,
    required this.period,
    required this.dueDate,
    required this.expectedCents,
    required this.paidCents,
    required this.balanceCents,
    required this.status,
    required this.overdue,
    required this.daysToDue,
  });

  factory DueHistoryItem.fromJson(Map<String, dynamic> json) => DueHistoryItem(
    id: asInt(json['id_vencimiento']),
    period: parseApiDate(json['periodo'] as String),
    dueDate: parseApiDate(json['fecha_vencimiento'] as String),
    expectedCents: moneyToCents(json['valor_esperado']),
    paidCents: moneyToCents(json['pagado']),
    balanceCents: moneyToCents(json['saldo']),
    status: DueStatus.fromApi(json['estado']),
    overdue: json['vencido'] == true,
    daysToDue: asInt(json['dias_para_vencer']),
  );

  final int id;
  final DateTime period;
  final DateTime dueDate;
  final int expectedCents;
  final int paidCents;
  final int balanceCents;
  final DueStatus status;
  final bool overdue;
  final int daysToDue;
}
