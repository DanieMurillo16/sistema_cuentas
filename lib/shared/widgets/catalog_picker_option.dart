import 'package:flutter/material.dart';

/// Una opción del selector de catálogo (una categoría, un medio de pago): el
/// dato que se devuelve y cómo se ve (nombre, icono y color).
class CatalogPickerOption<T extends Object> {
  const CatalogPickerOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final T value;
  final String label;
  final IconData icon;
  final Color color;
}
