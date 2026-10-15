import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_visual_style.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

import '../../../helpers/movement_fixtures.dart';
import '../../../helpers/recurring_fixtures.dart';

void main() {
  group('CategoryStyle.tint', () {
    test('tema oscuro: el color elegido tal cual', () {
      final category = buildCategory(color: '#FACC15');
      expect(category.tint, const Color(0xFFFACC15));
    });

    test('tema claro: el color elegido, si es claro, se oscurece', () {
      AppColors.apply(Brightness.light);
      final category = buildCategory(color: '#FACC15');

      expect(HSLColor.fromColor(category.tint).lightness, closeTo(0.4, 0.01));
    });

    test('tema claro: uno ya oscuro se queda', () {
      AppColors.apply(Brightness.light);
      final category = buildCategory(color: '#1E3A8A');

      expect(category.tint, const Color(0xFF1E3A8A));
    });

    test('sin color elegido usa el de su tipo (ingreso o gasto) del tema', () {
      expect(
        buildCategory(type: MovementType.income).tint,
        MovementType.income.color,
      );
      expect(buildCategory().tint, MovementType.expense.color);
    });
  });

  group('ContactStyle.tint', () {
    test('tema claro: el color elegido, si es claro, se oscurece', () {
      AppColors.apply(Brightness.light);
      final contact = buildContact(color: '#84CC16');

      expect(
        HSLColor.fromColor(contact.tint).lightness,
        lessThanOrEqualTo(0.41),
      );
    });

    test('sin color: el acento del tema activo', () {
      expect(buildContact().tint, AppColors.accent);
      AppColors.apply(Brightness.light);
      expect(buildContact().tint, AppColors.accent);
    });
  });
}
