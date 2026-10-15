import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Medio de pago (Nequi, Bancolombia, efectivo…): obligatorio en todo movimiento.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.active,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: asInt(json['id_medio']),
    name: json['nombre'] as String,
    active: json['activo'] != false,
  );

  final int id;
  final String name;
  final bool active;
}
