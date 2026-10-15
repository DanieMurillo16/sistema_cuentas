import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_visual_style.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/manage_list_scaffold.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

/// Ajustes → Categorías: ver, crear, editar y eliminar (ingresos primero, luego
/// gastos). Cada usuario maneja las suyas, sin permiso aparte.
/// pantalla → categoriesProvider → CatalogsRepository → catalogos/categorias.php
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ManageListScaffold(
      title: 'Categorías',
      state: ref.watch(visibleCategoriesProvider),
      onRetry: () => ref.invalidate(categoriesProvider),
      emptyTitle: 'Sin categorías',
      emptyMessage:
          'Crea las categorías con las que clasificas tus movimientos.',
      createTooltip: 'Nueva categoría',
      onCreate: () => showCategoryDialog(context),
      itemBuilder: (context, category) => ManageTile(
        key: ValueKey('category-${category.id}'),
        title: category.name,
        icon: category.iconData,
        tint: category.tint,
        subtitle: [
          category.type.isIncome ? 'Ingreso' : 'Gasto',
          if (category.isCapital) 'Capital',
        ].join(' · '),
        inactive: !category.active,
        onTap: () => showCategoryDialog(context, category: category),
      ),
    );
  }
}
