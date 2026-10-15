import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';

/// Cómo se ve cada tipo en toda la app, en un solo lugar: ingresos en verde
/// (entra) y gastos en rojo (sale).
extension MovementTypeStyle on MovementType {
  /// «Ingresos» / «Gastos».
  String get plural => isIncome ? 'Ingresos' : 'Gastos';

  /// El color de una cifra o de un texto sobre una superficie oscura.
  Color get color => isIncome ? AppColors.income : AppColors.expense;

  /// El color de un relleno con texto blanco encima (conmutadores, tarjetas).
  Color get fill => isIncome ? AppColors.success : AppColors.error;

  IconData get trendIcon =>
      isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded;
}
