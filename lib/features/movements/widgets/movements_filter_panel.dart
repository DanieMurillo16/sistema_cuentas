import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/movements/models/movements_filter.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_date_range_field.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_catalog_pickers.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';

/// Los filtros de la lista: fechas, categoría y medio de pago, y «Limpiar» para
/// volver al mes completo.
class MovementsFilterPanel extends ConsumerWidget {
  const MovementsFilterPanel({super.key, required this.type});

  final MovementType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(movementsFilterProvider(type));
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(movementsFilterProvider(type).notifier);
    final categories = ref.watch(categoriesOfTypeProvider(type)).value ?? [];
    final methods = ref.watch(paymentMethodsProvider).value ?? [];
    Category? category;
    PaymentMethod? method;
    for (final c in categories) {
      if (c.id == filter.categoryId) category = c;
    }
    for (final m in methods) {
      if (m.id == filter.methodId) method = m;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDateRangeField(
          label: 'Fechas',
          range: filter.range,
          firstDate: MovementsFilter.firstDate,
          lastDate: MovementsFilter.lastDate(DateTime.now()),
          onChanged: notifier.setRange,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        AppFormPair(
          minWidth: DesignTokens.formPickPairMinWidth,
          equalHeight: true,
          first: CatalogPickCard(
            label: 'Categoría',
            placeholder: 'Todas',
            placeholderIcon: Icons.category_outlined,
            selected: category == null ? null : categoryOption(category),
            onClear: () => notifier.setCategory(null),
            onTap: () async {
              final picked = await pickCategory(
                context,
                ref,
                type: type,
                items: categories,
                selected: category,
                canCreate: false,
              );
              if (picked != null) notifier.setCategory(picked.id);
            },
          ),
          second: CatalogPickCard(
            label: 'Medio de pago',
            placeholder: 'Todos',
            placeholderIcon: Icons.account_balance_wallet_outlined,
            selected: method == null ? null : methodOption(method),
            onClear: () => notifier.setMethod(null),
            onTap: () async {
              final picked = await pickMethod(
                context,
                ref,
                items: methods,
                selected: method,
                canCreate: false,
              );
              if (picked != null) notifier.setMethod(picked.id);
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: filter.isModifiedFrom(month) ? notifier.reset : null,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpiar filtros'),
          ),
        ),
      ],
    );
  }
}
