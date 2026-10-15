import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';

/// Aviso en la ficha de un pago recurrente cuya categoría ya fue eliminada: el
/// acuerdo sigue funcionando con ella (los pagos la heredan), pero ya no existe
/// en las categorías. Si la categoría está bien, no se pinta nada.
class DeletedCategoryNotice extends ConsumerWidget {
  const DeletedCategoryNotice({super.key, required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    if (category == null || !category.deleted) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: DesignTokens.iconMd,
                color: AppColors.warningText,
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Text(
                  'La categoría «${category.name}» ya no existe. Los pagos de '
                  'este acuerdo siguen usándola.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
