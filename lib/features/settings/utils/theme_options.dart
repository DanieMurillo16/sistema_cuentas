import 'package:flutter/material.dart';

/// Cómo se presenta cada tema en la pantalla «Tema» y en Ajustes.
extension ThemeModeLabels on ThemeMode {
  String get label => switch (this) {
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
    ThemeMode.system => 'Automático',
  };

  /// Lo que dice bajo el nombre: qué hace.
  String get description => switch (this) {
    ThemeMode.light => 'Fondo blanco, para ambientes con luz',
    ThemeMode.dark => 'Fondo oscuro, más suave de noche',
    ThemeMode.system => 'Sigue el modo del teléfono',
  };

  IconData get icon => switch (this) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.smartphone_rounded,
  };
}

/// El orden en que se ofrecen.
const themeOptions = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
