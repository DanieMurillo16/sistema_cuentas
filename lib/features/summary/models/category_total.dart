import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Lo que sumó una categoría en el mes (calculado por el servidor).
class CategoryTotal {
  const CategoryTotal({
    required this.type,
    required this.categoryId,
    required this.name,
    required this.isCapital,
    required this.totalCents,
    required this.count,
  });

  factory CategoryTotal.fromJson(Map<String, dynamic> json) => CategoryTotal(
    type: MovementType.fromApi(json['tipo']),
    categoryId: asInt(json['id_categoria']),
    name: json['categoria'] as String? ?? '',
    isCapital: json['es_capital'] == true,
    totalCents: moneyToCents(json['total']),
    count: asInt(json['cantidad']),
  );

  final MovementType type;
  final int categoryId;
  final String name;
  final bool isCapital;
  final int totalCents;
  final int count;
}
