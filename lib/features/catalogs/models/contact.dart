import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Persona o entidad con la que se tiene un acuerdo (quien me paga, a quien pago).
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.active,
    this.phone,
    this.note,
    this.icon,
    this.color,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: asInt(json['id_contacto']),
    name: json['nombre'] as String,
    active: json['activo'] != false,
    phone: asOptionalText(json['telefono']),
    note: asOptionalText(json['nota']),
    icon: asOptionalText(json['icono']),
    color: asOptionalText(json['color']),
  );

  final int id;
  final String name;
  final bool active;
  final String? phone;
  final String? note;

  /// Llave del icono elegido (ver `CatalogVisuals`) y color `#RRGGBB`.
  final String? icon;
  final String? color;
}
