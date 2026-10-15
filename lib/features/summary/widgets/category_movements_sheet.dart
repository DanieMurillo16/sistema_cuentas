import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/summary/widgets/category_movement_tile.dart';
import 'package:sistema_cuentas/features/summary/widgets/category_movements_header.dart';
import 'package:sistema_cuentas/features/summary/providers/category_movements_provider.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';

/// Hoja con los movimientos de una categoría del mes (al tocarla en la dona).
Future<void> showCategoryMovementsSheet(
  BuildContext context, {
  required int categoryId,
  required String name,
  required MovementType type,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) =>
        CategoryMovementsSheet(categoryId: categoryId, name: name, type: type),
  );
}

class CategoryMovementsSheet extends ConsumerWidget {
  const CategoryMovementsSheet({
    super.key,
    required this.categoryId,
    required this.name,
    required this.type,
  });

  final int categoryId;
  final String name;
  final MovementType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      categoryMovementsProvider((categoryId: categoryId, type: type)),
    );
    final month = ref.watch(selectedMonthProvider);
    final hidden = ref.watch(balancesHiddenProvider);
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: constraints.maxHeight * DesignTokens.sheetMaxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryMovementsHeader(
              name: name,
              count: items.length,
              month: month,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceMd,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.spaceSm),
                itemBuilder: (context, index) => CategoryMovementTile(
                  movement: items[index],
                  hidden: hidden,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
