import 'package:flutter/material.dart';

/// Medidas de la app: espaciados, radios, alturas, anchos y puntos de quiebre.
/// Las vistas usan estos valores en vez de números sueltos. Los colores van en
/// `AppColors` y los estilos de texto en `AppTextTheme`.
abstract final class DesignTokens {
  // Espaciado
  static const double spaceXxs = 2;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const EdgeInsets pagePadding = EdgeInsets.all(spaceLg);

  // Radios de borde
  static const double radiusSm = 8;
  static const double radiusMd = 12; // campos y botones
  static const double radiusLg = 20; // tarjetas y diálogos
  static const double radiusXl = 28; // tarjeta de balance y hojas inferiores
  static const double radiusPill = 999;

  // Alturas y tamaños de controles
  static const double buttonHeight = 52;
  static const double dialogButtonHeight = 44;
  static const double controlMinHeight = 48;
  static const double actionSize = 40;
  static const double actionIconSize = 20;
  static const double iconSm = 16;
  static const double iconMd = 20;
  // Alto mínimo de un control pequeño dentro de una tarjeta.
  static const double compactTapTarget = 40;
  static const double iconLg = 28;
  static const double avatarSize = 44;
  static const double progressSize = 20;
  static const double barHeight = 6;
  // Tarjetas Ingresos/Gastos del balance: opacidad del relleno y del borde.
  static const double tintFill = 0.28;
  // Fondo muy tenue de un icono sobre una fila.
  static const double tintSoft = 0.14;
  static const double tintBorder = 0.7;
  static const double donutSize = 220;
  static const double donutThickness = 28;
  static const double donutThicknessSelected = 36;
  static const double donutCenterRadius = 70;
  static const double donutCenterPadding = 56;
  static const double donutSliceGap = 3;
  static const double chartHeight = 200;
  static const double chartBarWidth = 10;
  static const double chartLineWidth = 3;
  // Hoja inferior de «nuevo movimiento»: como mucho esta parte del alto.
  static const double sheetMaxHeightFactor = 0.85;
  // Selector de icono y color: celda del icono, muestra del color y vista previa.
  static const double iconCellMaxExtent = 64;
  static const double colorSwatchSize = 40;
  static const double visualPreviewSize = 64;
  // Alto mínimo del cuerpo de la hoja para mostrar buscador y rejilla juntos.
  static const double searchMinRoom = 100;
  static const double visualBadgeRatio = 0.5;
  static const double placeholderIconSize = 56;
  static const double logoSize = 72;
  // Pantalla de carga: icono de cada mensaje, sus puntos y
  // el alto que se reserva al mensaje para que nada salte al cambiar.
  static const double splashBadgeSize = 56;
  static const double splashDotSize = 4;
  static const double splashDotActiveWidth = 16;
  static const double splashTipMinHeight = 124;
  // Lo que ocupa (a texto normal) el bloque de mensajes: se reserva
  // arriba del logo para que quede en el centro.
  static const double splashBelowReserve = 184;
  static const double headerLogoSize = 44;
  static const double floatingNavHeight = 56;
  static const double floatingNavMaxWidth = 480;
  // Ancho del resaltado de la pestaña elegida en la píldora.
  static const double pillHighlightWidth = 72;
  static const double filterHeaderExtent = 68;
  static const double balanceCardMinHeight = 200;
  // Lo que ocupa la píldora desde el borde inferior (alto + relleno + borde +
  // margen): el contenido y el botón flotante se apartan esa distancia.
  static const double floatingNavFootprint = 76;
  // Separación de la píldora al borde inferior (pegada abajo, casi al borde).
  static const double floatingNavBottomGap = 4;
  // Relleno vertical de una fila del historial (compacta).
  static const double tileVerticalPadding = 12;
  // Espacio al final de una lista para que el botón flotante no tape el último.
  static const double fabClearance = 80;
  static const double logoPaddingRatio = 0.1;
  // Bajo este ancho de cabecera (x escala de texto) se oculta el logo.
  static const double headerLogoMinWidth = 380;
  static const double iconButtonSm = 32;

  // Anchos máximos y mínimos
  static const double dialogMaxWidth = 520;
  static const double dialogMaxHeight = 720;
  static const double contentMaxWidth = 1200;
  static const double loginMaxWidth = 420;
  static const double formMaxWidth = 560;
  static const double toastMaxWidth = 460;
  static const double menuMaxHeight = 260;
  static const double emptyActionMaxWidth = 280;
  static const double navigationRailWidth = 240;
  static const double formPairMinWidth = 280; // pareja de campos M
  static const double formShortPairMinWidth = 240; // pareja de campos XS/S
  // Pareja con un campo de fecha (su calendario ocupa ~50 px): más ancho.
  static const double formDatePairMinWidth = 320;
  // Pareja de desplegables con búsqueda (llevan lupa y flecha).
  static const double formDropdownPairMinWidth = 360;
  // Tarjeta que abre un selector (categoría, medio de pago) y tamaños de sus filas.
  static const double pickCardMinHeight = 72;
  // Pareja de tarjetas que abren un selector: el nombre necesita ancho (a 360 px útiles caben).
  static const double formPickPairMinWidth = 340;
  static const double pickerBadgeSize = 40;
  static const double pickerChipBadgeSize = 32;
  static const double pickerSmallBadgeSize = 28;
  // La «x» que quita lo elegido en una tarjeta de selector (opcional/filtro).
  static const double pickClearWidth = 40;
  static const double pickClearHeight = 24;
  static const double kpiMinWidth = 320;
  static const double kpiSlideWidth = 260;

  // Puntos de quiebre (ver ~/.claude/flutter-base/responsive.md)
  static const double compactLayoutWidth = 600; // < 600: teléfono
  static const double wideLayoutWidth = 900; // >= 900: menú lateral y tablas
  static const double expandedLayoutWidth = 1100; // >= 1100: 3 columnas

  // Espacio libre al final de una lista para que el botón flotante no tape el
  // último ítem.
  static const double listBottomSpace = 100;

  // Duraciones de animación
  static const Duration animationFast = Duration(milliseconds: 180);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationNumber = Duration(milliseconds: 500);
  // El paso del splash al login o a Inicio (fundido entre pantallas).
  static const Duration animationRoute = Duration(milliseconds: 450);
  // El monto que «vuela» hasta su tarjeta al registrar (vuelo + destello). A
  // propósito más largo que el resto (el usuario pidió poder apreciarlo).
  static const Duration animationFlight = Duration(milliseconds: 1600);

  // Curva por defecto de todas las animaciones (entrada suave, sin rebote).
  static const Curve curve = Curves.easeOutCubic;
}
