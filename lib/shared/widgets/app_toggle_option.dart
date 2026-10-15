import 'package:flutter/material.dart';

/// Una opción de [AppToggle]: su valor, lo que se lee, su icono y, si lo tiene,
/// su color. El icono y el texto salen del `enum` que nombra la opción, no del
/// widget: así agregar un caso nuevo basta para que aparezca.
class AppToggleOption<T> {
  const AppToggleOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final T value;
  final String label;

  /// Sin icono la opción va solo con su texto, centrada.
  final IconData? icon;

  /// Color de la pastilla cuando **esta** opción está elegida. Solo donde la
  /// opción ya tiene color propio en el resto de la pantalla; sin él va el de
  /// marca, que es lo normal.
  final Color? color;
}
