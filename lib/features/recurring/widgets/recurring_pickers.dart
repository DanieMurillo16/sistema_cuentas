import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/features/catalogs/providers/contacts_provider.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_visual_style.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/contact_dialog.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_sheet.dart';

/// Cómo se ve un contacto dentro del selector y de su tarjeta.
CatalogPickerOption<Contact> contactOption(Contact contact) =>
    CatalogPickerOption(
      value: contact,
      label: contact.name,
      icon: contact.iconData,
      color: contact.tint,
    );

/// «Cada mes», «Cada 3 meses»…: cada cuántos meses se repite el pago.
CatalogPickerOption<int> cadenceOption(int everyMonths) => CatalogPickerOption(
  value: everyMonths,
  label: RecurringRules.cadenceLabel(everyMonths),
  icon: Icons.event_repeat_rounded,
  color: AppColors.accent,
);

/// Selector de contacto (hoja inferior); devuelve el elegido o el recién
/// creado desde «Nuevo contacto», o `null` si se cierra.
Future<Contact?> pickContact(
  BuildContext context,
  WidgetRef ref, {
  required List<Contact> items,
  required Contact? selected,
}) => showCatalogPicker<Contact>(
  context,
  title: 'Contacto',
  createLabel: 'Nuevo contacto',
  options: [for (final c in items) contactOption(c)],
  selected: items.where((c) => c.id == selected?.id).firstOrNull,
  onCreate: () async {
    final before = {for (final c in items) c.id};
    await showContactDialog(context);
    final now = ref.read(activeContactsProvider).value ?? const [];
    return now.where((c) => !before.contains(c.id)).firstOrNull;
  },
);

/// Selector de cada cuántos meses se repite: pocas opciones, sin buscador.
Future<int?> pickCadence(BuildContext context, {required int selected}) =>
    showCatalogPicker<int>(
      context,
      title: 'Se repite',
      createLabel: '',
      options: [
        for (final months in RecurringRules.everyMonthsOptions)
          cadenceOption(months),
      ],
      selected: selected,
      searchable: false,
    );
