import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_visual_style.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

/// Círculo de una fila: el icono y color de su categoría si se conoce
/// ([categoryId]) y, si no, la flecha de un ingreso (entra, verde) o de un
/// gasto (sale, rojo).
class MovementIcon extends ConsumerWidget {
  const MovementIcon({super.key, required this.type, this.categoryId});

  final MovementType type;
  final int? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = categoryId == null
        ? null
        : ref.watch(categoryByIdProvider(categoryId!));
    final color = category?.tint ?? type.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: DesignTokens.tintSoft),
      ),
      child: SizedBox.square(
        dimension: DesignTokens.avatarSize,
        child: Icon(
          category?.iconData ??
              (type.isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded),
          color: color,
          size: DesignTokens.iconMd,
        ),
      ),
    );
  }
}
