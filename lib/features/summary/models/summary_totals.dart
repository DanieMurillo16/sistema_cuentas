import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Totales del mes que calcula el servidor (en centavos). Nada se precalcula
/// en la app: se muestran tal cual llegan.
class SummaryTotals {
  const SummaryTotals({
    required this.incomeTotalCents,
    required this.expenseTotalCents,
    required this.netFlowCents,
    required this.operatingBalanceCents,
    required this.capitalRecoveredCents,
    required this.capitalDeliveredCents,
    required this.movementCount,
  });

  factory SummaryTotals.fromJson(Map<String, dynamic> json) => SummaryTotals(
    incomeTotalCents: moneyToCents(json['ingresos_total']),
    expenseTotalCents: moneyToCents(json['gastos_total']),
    netFlowCents: moneyToCents(json['flujo_neto']),
    operatingBalanceCents: moneyToCents(json['balance_operativo']),
    capitalRecoveredCents: moneyToCents(json['capital_recuperado']),
    capitalDeliveredCents: moneyToCents(json['capital_entregado']),
    movementCount: asInt(json['movimientos']),
  );

  final int incomeTotalCents;
  final int expenseTotalCents;

  /// Lo que entró menos lo que salió, con capital: el «Balance disponible».
  final int netFlowCents;
  final int operatingBalanceCents;
  final int capitalRecoveredCents;
  final int capitalDeliveredCents;
  final int movementCount;
}
