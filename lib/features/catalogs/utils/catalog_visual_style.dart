import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

/// Cómo se ve una categoría: el icono y el color que eligió el usuario o, si
/// no eligió, la flecha y el color de su tipo (verde ingreso, rojo gasto).
extension CategoryStyle on Category {
  IconData get iconData => CatalogVisuals.iconFor(
    icon,
    fallback: type.isIncome
        ? Icons.south_west_rounded
        : Icons.north_east_rounded,
  );

  Color get tint => CatalogVisuals.readable(
    CatalogVisuals.colorFor(color, fallback: type.color),
  );
}

/// Cómo se ve un contacto: icono y color elegidos o, si no, una persona.
extension ContactStyle on Contact {
  IconData get iconData =>
      CatalogVisuals.iconFor(icon, fallback: Icons.person_outline_rounded);

  Color get tint => CatalogVisuals.readable(
    CatalogVisuals.colorFor(color, fallback: AppColors.accent),
  );
}
