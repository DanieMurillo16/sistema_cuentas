import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Clasificación de un movimiento. Las de capital se separan en el resumen.
class Category {
  const Category({
    required this.id,
    required this.type,
    required this.name,
    required this.isCapital,
    required this.active,
    this.deleted = false,
    this.icon,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: asInt(json['id_categoria']),
    type: MovementType.fromApi(json['tipo']),
    name: json['nombre'] as String,
    isCapital: json['es_capital'] == true,
    active: json['activo'] != false,
    deleted: json['eliminada'] == true,
    icon: asOptionalText(json['icono']),
    color: asOptionalText(json['color']),
  );

  final int id;
  final MovementType type;
  final String name;
  final bool isCapital;
  final bool active;

  /// Eliminada por quien la creó: ya no se usa ni se lista en Ajustes, pero
  /// sigue viniendo del servidor para pintar lo registrado con ella.
  final bool deleted;

  /// Llave del icono elegido (ver `CatalogVisuals`) y color `#RRGGBB`; vacíos
  /// si nunca se eligieron.
  final String? icon;
  final String? color;

  /// La misma categoría, ya eliminada (y por tanto inactiva).
  Category asDeleted() => Category(
    id: id,
    type: type,
    name: name,
    isCapital: isCapital,
    active: false,
    deleted: true,
    icon: icon,
    color: color,
  );
}
