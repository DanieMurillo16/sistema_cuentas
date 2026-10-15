import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Lo que entró o salió por un medio de pago en el mes (calculado por el servidor).
class MethodTotal {
  const MethodTotal({
    required this.type,
    required this.methodId,
    required this.name,
    required this.totalCents,
    required this.count,
  });

  factory MethodTotal.fromJson(Map<String, dynamic> json) => MethodTotal(
    type: MovementType.fromApi(json['tipo']),
    methodId: asInt(json['id_medio']),
    name: json['medio'] as String? ?? '',
    totalCents: moneyToCents(json['total']),
    count: asInt(json['cantidad']),
  );

  final MovementType type;
  final int methodId;
  final String name;
  final int totalCents;
  final int count;
}
