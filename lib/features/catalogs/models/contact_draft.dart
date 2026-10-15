/// Crear o editar un contacto. Al editar se mandan todos los datos: lo opcional
/// que se omita se borra en el servidor.
class ContactDraft {
  const ContactDraft({
    required this.name,
    required this.active,
    this.id,
    this.phone,
    this.note,
    this.icon,
    this.color,
    this.visualChanged = false,
  });

  final int? id;
  final String name;
  final bool active;
  final String? phone;
  final String? note;
  final String? icon;
  final String? color;

  /// Solo si el usuario tocó icono o color se mandan (un valor vacío los quita).
  final bool visualChanged;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id_contacto': id,
    'nombre': name,
    'activo': active,
    if (phone != null) 'telefono': phone,
    if (note != null) 'nota': note,
    if (visualChanged) ...{'icono': icon, 'color': color},
  };
}
