import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_form_rules.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_catalog_pickers.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';

/// Las dos tarjetas (categoría y medio de pago), lado a lado si hay ancho. Cada
/// una abre su selector; los catálogos ya cargaron (lo asegura quien la usa).
class MovementCatalogPair extends ConsumerWidget {
  const MovementCatalogPair({
    super.key,
    required this.type,
    required this.category,
    required this.method,
    required this.onCategoryChanged,
    required this.onMethodChanged,
  });

  final MovementType type;
  final Category? category;
  final PaymentMethod? method;
  final ValueChanged<Category?> onCategoryChanged;
  final ValueChanged<PaymentMethod?> onMethodChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryItems =
        ref.watch(categoriesForTypeProvider(type)).value ?? const [];
    final methodItems =
        ref.watch(activePaymentMethodsProvider).value ?? const [];
    return AppFormPair(
      minWidth: DesignTokens.formPickPairMinWidth,
      equalHeight: true,
      first: CatalogPickCard(
        label: 'Categoría',
        placeholderIcon: Icons.category_outlined,
        selected: category == null ? null : categoryOption(category!),
        validator: () => MovementFormRules.validateCategory(category),
        onTap: () async {
          final picked = await pickCategory(
            context,
            ref,
            type: type,
            items: categoryItems,
            selected: category,
          );
          if (picked != null) onCategoryChanged(picked);
        },
      ),
      second: CatalogPickCard(
        label: 'Medio de pago',
        placeholderIcon: Icons.account_balance_wallet_outlined,
        selected: method == null ? null : methodOption(method!),
        validator: () => MovementFormRules.validatePaymentMethod(method),
        onTap: () async {
          final picked = await pickMethod(
            context,
            ref,
            items: methodItems,
            selected: method,
          );
          if (picked != null) onMethodChanged(picked);
        },
      ),
    );
  }
}
