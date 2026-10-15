import 'package:flutter/material.dart';

/// Los colores de un tema (claro u oscuro). Los de marca y estado son iguales
/// en los dos; cambian los neutros y los que se leen sobre ellos.
class AppPalette {
  const AppPalette({
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.text,
    required this.muted,
    required this.border,
    required this.inputBorder,
    required this.income,
    required this.expense,
    required this.warningText,
    required this.shadow,
    required this.navHighlight,
    required this.navBar,
    required this.chart,
  });

  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color text;
  final Color muted;
  final Color border;
  final Color inputBorder;
  final Color income;
  final Color expense;
  final Color warningText;
  final Color shadow;
  final Color navHighlight;
  final Color navBar;
  final List<Color> chart;

  static const dark = AppPalette(
    accent: Color(0xFF2DD4BF),
    background: Color(0xFF050A14),
    surface: Color(0xFF111827),
    surfaceHigh: Color(0xFF1A2333),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    border: Color(0xFF233044),
    // Borde de campos en reposo: contraste no textual (≈ 3:1) contra el fondo.
    inputBorder: Color(0xFF475569),
    // Dinero legible sobre superficies oscuras.
    income: Color(0xFF34D399),
    expense: Color(0xFFF87171),
    warningText: Color(0xFFFBBF24),
    shadow: Color(0x66000000),
    navHighlight: Color(0x4D0F8A7E),
    navBar: Color(0xF0050A14),
    chart: [
      Color(0xFF2DD4BF),
      Color(0xFFF59E0B),
      Color(0xFF818CF8),
      Color(0xFFFB7185),
      Color(0xFF38BDF8),
      Color(0xFFA3E635),
      Color(0xFFC084FC),
      Color(0xFFFB923C),
    ],
  );

  static const light = AppPalette(
    accent: Color(0xFF0B7A6F),
    background: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEAEFF5),
    text: Color(0xFF0F172A),
    muted: Color(0xFF556274),
    border: Color(0xFFDDE3EA),
    inputBorder: Color(0xFF94A3B8),
    // Dinero legible sobre superficies claras.
    income: Color(0xFF08764E),
    expense: Color(0xFFCF2323),
    warningText: Color(0xFFB45309),
    shadow: Color(0x1A0F172A),
    navHighlight: Color(0x330B7A6F),
    navBar: Color(0xF0FFFFFF),
    // Tonos más hondos para que se lean sobre blanco.
    chart: [
      Color(0xFF0D9488),
      Color(0xFFD97706),
      Color(0xFF6366F1),
      Color(0xFFE11D48),
      Color(0xFF0284C7),
      Color(0xFF65A30D),
      Color(0xFF9333EA),
      Color(0xFFEA580C),
    ],
  );
}

/// La paleta de la app. Las vistas nunca escriben un color: todo sale de aquí o
/// del `ColorScheme`.
///
/// - [brand] es el color de marca (`#0F4C5C`): identidad, logo y la tarjeta de
///   balance. Sobre fondo oscuro es demasiado hundido para texto y botones.
/// - [primary] es la acción principal (botones, selección) y [accent] el verde
///   azulado para cifras, enlaces e iconos sobre las superficies.
/// - Los neutros siguen al tema activo: [apply] lo cambia (la app reconstruye
///   todo al hacerlo). Lo que va sobre la tarjeta de balance o sobre un relleno
///   de color usa [onBrand], que no cambia.
abstract final class AppColors {
  static AppPalette _palette = AppPalette.dark;

  /// Activa la paleta del tema [brightness]. Es idempotente: `App` la llama
  /// antes de armar el tema y `AppTheme` también, para que un tema armado fuera
  /// de `App` (pruebas, vistas previas) use su propia paleta.
  static void apply(Brightness brightness) {
    _palette = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
  }

  /// ¿Está activo el tema claro?
  static bool get isLight => identical(_palette, AppPalette.light);

  // Marca y acentos (iguales en claro y oscuro)
  static const Color brand = Color(0xFF0F4C5C);
  static const Color primary = Color(0xFF0B7A6F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static Color get accent => _palette.accent;

  // Neutros
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get surfaceHigh => _palette.surfaceHigh;
  static Color get text => _palette.text;
  static Color get muted => _palette.muted;
  static Color get border => _palette.border;
  static Color get inputBorder => _palette.inputBorder;

  // Dinero: ingreso (entra) y gasto (sale)
  static Color get income => _palette.income;
  static Color get expense => _palette.expense;
  static Color get warningText => _palette.warningText;

  // Texto y iconos sobre la tarjeta de balance y sobre rellenos de color
  // (siempre claros, en cualquier tema).
  static const Color onBrand = Color(0xFFF1F5F9);

  // Degradado de la tarjeta de balance (de la marca a un verde azulado vivo).
  static const Color balanceStart = brand;
  static const Color balanceEnd = Color(0xFF0E7A70);

  // Estados (los usan los avisos/toasts con texto blanco encima)
  static const Color success = Color(0xFF177A4B);
  static const Color warning = Color(0xFFA85F00);
  static const Color error = Color(0xFFD93C3C);
  static const Color info = Color(0xFF2F6FE0);

  // Colores de las gráficas (una dona o barras por categoría): distinguibles
  // entre sí y legibles sobre la superficie del tema activo.
  static List<Color> get chart => _palette.chart;

  static Color get shadow => _palette.shadow;
  // Capas translúcidas sobre la tarjeta de balance (tarjetas pequeñas y borde).
  static const Color onBrandSoft = Color(0x1FFFFFFF);
  static const Color onBrandBorder = Color(0x33FFFFFF);
  static const Color onBrandMuted = Color(0xE6FFFFFF);

  // Barra de navegación flotante: fondo casi opaco para leer sobre listas.
  // Resaltado de la pestaña elegida en la píldora (visible sobre [navBar]).
  static Color get navHighlight => _palette.navHighlight;
  static Color get navBar => _palette.navBar;
  static const Color transparent = Color(0x00000000);
}
