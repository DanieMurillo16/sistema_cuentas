import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';

/// Escala tipográfica única. La familia de fuente NO se escribe aquí: la pone
/// `AppTheme.fontFamily` para toda la app. Las vistas leen estos estilos con
/// `Theme.of(context).textTheme`; nunca `TextStyle(fontSize: 14)` suelto.
abstract final class AppTextTheme {
  /// Los colores siguen al tema activo (`AppColors.apply`): se lee al armar el
  /// `ThemeData`, no una sola vez.
  static TextTheme get base => TextTheme(
    displayMedium: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
    bodyLarge: TextStyle(fontSize: 14, color: AppColors.text),
    bodyMedium: TextStyle(fontSize: 13, color: AppColors.text),
    bodySmall: TextStyle(fontSize: 12, color: AppColors.muted),
    labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, color: AppColors.muted),
  );
}
