import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_text_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

abstract final class AppTheme {
  // CAMBIAR POR PROYECTO: familia de fuente. Debe estar empaquetada en
  // assets/fonts/ y declarada en pubspec.yaml (pesos 400, 500, 600 y 700).
  // Nunca google_fonts en ejecución: provoca un cambio visual al arrancar.
  static const String fontFamily = 'Inter';

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  /// Los colores salen de `AppColors`, que ya debe tener activa la paleta de
  /// [brightness] (`AppColors.apply`).
  static ThemeData _build(Brightness brightness) {
    AppColors.apply(brightness);
    final dark = brightness == Brightness.dark;
    // El primary se declara explícito: fromSeed no puede cambiarlo ni añadir
    // un tinte violeta a las superficies.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.accent,
          onSecondary: dark ? AppColors.background : AppColors.onPrimary,
          tertiary: AppColors.accent,
          primaryContainer: AppColors.brand,
          secondaryContainer: AppColors.surfaceHigh,
          tertiaryContainer: AppColors.surfaceHigh,
          onPrimaryContainer: AppColors.text,
          onSecondaryContainer: AppColors.accent,
          onTertiaryContainer: AppColors.accent,
          surface: AppColors.surface,
          surfaceContainerLowest: AppColors.background,
          surfaceContainerLow: AppColors.surface,
          surfaceContainer: AppColors.surface,
          surfaceContainerHigh: AppColors.surfaceHigh,
          surfaceContainerHighest: AppColors.surfaceHigh,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          error: AppColors.expense,
          onError: dark ? AppColors.background : AppColors.onPrimary,
          surfaceTint: AppColors.transparent,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      textTheme: AppTextTheme.base,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
      ),
      dividerTheme: DividerThemeData(color: AppColors.border),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceHigh,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXl),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        surfaceTintColor: AppColors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceHigh,
        selectedIconTheme: IconThemeData(color: AppColors.accent),
        unselectedIconTheme: IconThemeData(color: AppColors.muted),
        selectedLabelTextStyle: TextStyle(color: AppColors.accent),
        unselectedLabelTextStyle: TextStyle(color: AppColors.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: _inputBorder(AppColors.inputBorder),
        enabledBorder: _inputBorder(AppColors.inputBorder),
        focusedBorder: _inputBorder(AppColors.accent),
        errorBorder: _inputBorder(AppColors.expense),
        focusedErrorBorder: _inputBorder(AppColors.expense),
        labelStyle: TextStyle(color: AppColors.muted),
        hintStyle: TextStyle(color: AppColors.muted),
        contentPadding: const EdgeInsets.all(DesignTokens.spaceMd),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, DesignTokens.dialogButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, DesignTokens.dialogButtonHeight),
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      switchTheme: SwitchThemeData(
        // Apagado se ve en los dos temas: pomo apagado, pista con contorno.
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onBrand
              : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.transparent
              : AppColors.inputBorder,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
    borderSide: BorderSide(color: color),
  );

  /// Campos compactos para diálogos: alto mínimo de 48, padding vertical
  /// reducido y sin altura máxima que recorte texto ampliado o errores.
  static ThemeData compactForm(ThemeData theme) => theme.copyWith(
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      isDense: true,
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceSm,
      ),
    ),
  );
}
