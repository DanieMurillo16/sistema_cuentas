import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/contacts_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_catalogs_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_form_pair.dart';
import 'package:sistema_cuentas/shared/widgets/app_retry_message.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_catalog_pickers.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_pickers.dart';

/// Categoría (obligatoria) y contacto (opcional): dos tarjetas lado a lado que
/// abren su selector desde abajo, como en el formulario de un movimiento. Si los catálogos no cargan o
/// no hay categorías, lo dice y permite reintentar.
class RecurringCatalogFields extends ConsumerWidget {
  const RecurringCatalogFields({
    super.key,
    required this.type,
    required this.category,
    required this.contact,
    required this.onCategoryChanged,
    required this.onContactChanged,
  });

  final MovementType type;
  final Category? category;
  final Contact? contact;
  final ValueChanged<Category?> onCategoryChanged;
  final ValueChanged<Contact?> onContactChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(recurringCategoriesProvider(type));
    final contacts = ref.watch(activeContactsProvider);
    final error =
        (categories.hasValue ? null : categories.error) ??
        (contacts.hasValue ? null : contacts.error);
    if (error != null) {
      return AppRetryMessage(
        text: userErrorMessage(error),
        onRetry: () {
          ref.invalidate(categoriesProvider);
          ref.invalidate(contactsProvider);
        },
      );
    }
    if (!categories.hasValue || !contacts.hasValue) {
      return const LinearProgressIndicator();
    }
    if (categories.requireValue.isEmpty) {
      return AppRetryMessage(
        text:
            'Aún no tienes categorías de '
            '${type.isIncome ? 'ingresos' : 'gastos'} activas.',
        onRetry: () => ref.invalidate(categoriesProvider),
      );
    }
    return AppFormPair(
      minWidth: DesignTokens.formPickPairMinWidth,
      equalHeight: true,
      first: CatalogPickCard(
        label: 'Categoría',
        placeholderIcon: Icons.category_outlined,
        selected: category == null ? null : categoryOption(category!),
        validator: () => RecurringRules.validateCategory(category),
        onTap: () async {
          final picked = await pickCategory(
            context,
            ref,
            type: type,
            items: categories.requireValue,
            selected: category,
            allow: (c) => !c.isCapital,
          );
          if (picked != null) onCategoryChanged(picked);
        },
      ),
      second: CatalogPickCard(
        label: 'Contacto (opcional)',
        placeholder: 'Ninguno',
        placeholderIcon: Icons.person_outline_rounded,
        selected: contact == null ? null : contactOption(contact!),
        onClear: () => onContactChanged(null),
        onTap: () async {
          final picked = await pickContact(
            context,
            ref,
            items: contacts.requireValue,
            selected: contact,
          );
          if (picked != null) onContactChanged(picked);
        },
      ),
    );
  }
}
