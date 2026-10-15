/// Lo que se eligió en el selector de icono y color. Vacío = «sin elegir»
/// (la fila vuelve a su aspecto por defecto).
class CatalogVisualChoice {
  const CatalogVisualChoice({this.icon, this.color});

  /// Llave del icono (ver `CatalogVisuals`) y color `#RRGGBB`.
  final String? icon;
  final String? color;
}
