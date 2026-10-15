import 'package:sistema_cuentas/core/models/movement_type.dart';

/// Crear o editar una categoría. El tipo solo se elige al crear: no cambia.
class CategoryDraft {
  const CategoryDraft({
    required this.type,
    required this.name,
    required this.isCapital,
    required this.active,
    this.id,
    this.icon,
    this.color,
    this.visualChanged = false,
  });

  final int? id;
  final MovementType type;
  final String name;
  final bool isCapital;
  final bool active;
  final String? icon;
  final String? color;

  /// Solo si el usuario tocó icono o color se mandan: así un servidor sin esos
  /// campos sigue guardando categorías, y un valor vacío los quita.
  final bool visualChanged;

  Map<String, dynamic> toJson() => {
    if (id == null) 'tipo': type.apiValue else 'id_categoria': id,
    'nombre': name,
    'es_capital': isCapital,
    'activo': active,
    if (visualChanged) ...{'icono': icon, 'color': color},
  };
}
