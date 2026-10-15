import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Lo que falta del mes para un tipo: por cobrar (ingresos) o por pagar (gastos).
class SummaryDues {
  const SummaryDues({
    required this.type,
    required this.balanceCents,
    required this.overdueBalanceCents,
    required this.pendingCount,
    required this.overdueCount,
  });

  factory SummaryDues.fromJson(Map<String, dynamic> json) => SummaryDues(
    type: MovementType.fromApi(json['tipo']),
    balanceCents: moneyToCents(json['saldo']),
    overdueBalanceCents: moneyToCents(json['saldo_vencido']),
    pendingCount: asInt(json['cantidad_pendiente']),
    overdueCount: asInt(json['cantidad_vencida']),
  );

  final MovementType type;
  final int balanceCents;

  /// La parte del saldo que ya venció.
  final int overdueBalanceCents;
  final int pendingCount;
  final int overdueCount;
}
