import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

void main() {
  test('plural: «Ingresos» y «Gastos»', () {
    expect(MovementType.income.plural, 'Ingresos');
    expect(MovementType.expense.plural, 'Gastos');
  });

  test(
    'color: verde para ingresos y rojo para gastos (sobre fondo oscuro)',
    () {
      expect(MovementType.income.color, AppColors.income);
      expect(MovementType.expense.color, AppColors.expense);
      expect(MovementType.income.color, isNot(MovementType.expense.color));
    },
  );

  test('fill: los rellenos de estado (éxito / error)', () {
    expect(MovementType.income.fill, AppColors.success);
    expect(MovementType.expense.fill, AppColors.error);
  });

  test('icono de tendencia: sube para ingresos y baja para gastos', () {
    expect(MovementType.income.trendIcon, Icons.trending_up_rounded);
    expect(MovementType.expense.trendIcon, Icons.trending_down_rounded);
  });
}
