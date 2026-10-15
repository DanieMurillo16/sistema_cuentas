import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Totales de los vencimientos de un mes para un tipo (los calcula el servidor).
class DueTotals {
  const DueTotals({
    required this.type,
    required this.count,
    required this.expectedCents,
    required this.paidCents,
    required this.balanceCents,
    required this.pendingCount,
    required this.overdueCount,
  });

  factory DueTotals.fromJson(Map<String, dynamic> json) => DueTotals(
    type: MovementType.fromApi(json['tipo']),
    count: asInt(json['cantidad']),
    expectedCents: moneyToCents(json['esperado']),
    paidCents: moneyToCents(json['pagado']),
    balanceCents: moneyToCents(json['saldo']),
    pendingCount: asInt(json['cantidad_pendiente']),
    overdueCount: asInt(json['cantidad_vencida']),
  );

  final MovementType type;
  final int count;
  final int expectedCents;
  final int paidCents;

  /// Lo que falta por cobrar (ingresos) o por pagar (gastos).
  final int balanceCents;
  final int pendingCount;
  final int overdueCount;
}
