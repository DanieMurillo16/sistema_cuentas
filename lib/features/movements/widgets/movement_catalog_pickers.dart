import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_visual_style.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/category_dialog.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/payment_method_dialog.dart';
import 'package:sistema_cuentas/features/movements/providers/frequent_catalog_provider.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_sheet.dart';

/// Cómo se ve una categoría o un medio dentro del selector y de su tarjeta.
CatalogPickerOption<Category> categoryOption(Category category) =>
    CatalogPickerOption(
      value: category,
      label: category.name,
      icon: category.iconData,
      color: category.tint,
    );

CatalogPickerOption<PaymentMethod> methodOption(PaymentMethod method) =>
    CatalogPickerOption(
      value: method,
      label: method.name,
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.accent,
    );

/// Abre el selector de categoría del tipo [type]; devuelve la elegida (o la
/// recién creada desde «Nueva categoría»), o `null` si se cierra.
Future<Category?> pickCategory(
  BuildContext context,
  WidgetRef ref, {
  required MovementType type,
  required List<Category> items,
  required Category? selected,
  bool canCreate = true,
  bool Function(Category category)? allow,
}) {
  final frequent = ref.read(frequentCategoriesProvider(type));
  return showCatalogPicker<Category>(
    context,
    title: 'Categoría',
    createLabel: 'Nueva categoría',
    options: [for (final c in items) categoryOption(c)],
    frequent: [for (final c in frequent) categoryOption(c)],
    selected: items.where((c) => c.id == selected?.id).firstOrNull,
    onCreate: !canCreate
        ? null
        : () async {
            final before = {for (final c in items) c.id};
            await showCategoryDialog(context, initialType: type);
            final now =
                ref.read(categoriesForTypeProvider(type)).value ?? const [];
            // `allow` descarta lo que el formulario no acepta (p. ej. una
            // categoría de capital en un pago recurrente).
            return now
                .where(
                  (c) => !before.contains(c.id) && (allow?.call(c) ?? true),
                )
                .firstOrNull;
          },
  );
}

/// Igual que [pickCategory], para el medio de pago.
Future<PaymentMethod?> pickMethod(
  BuildContext context,
  WidgetRef ref, {
  required List<PaymentMethod> items,
  required PaymentMethod? selected,
  bool canCreate = true,
}) {
  final frequent = ref.read(frequentMethodsProvider);
  return showCatalogPicker<PaymentMethod>(
    context,
    title: 'Medio de pago',
    createLabel: 'Nuevo medio de pago',
    options: [for (final m in items) methodOption(m)],
    frequent: [for (final m in frequent) methodOption(m)],
    selected: items.where((m) => m.id == selected?.id).firstOrNull,
    onCreate: !canCreate
        ? null
        : () async {
            final before = {for (final m in items) m.id};
            await showPaymentMethodDialog(context);
            final now =
                ref.read(activePaymentMethodsProvider).value ?? const [];
            return now.where((m) => !before.contains(m.id)).firstOrNull;
          },
  );
}
