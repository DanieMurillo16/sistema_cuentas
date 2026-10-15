import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/providers/contacts_provider.dart';
import 'package:sistema_cuentas/features/catalogs/utils/catalog_visual_style.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/contact_dialog.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';
import 'package:sistema_cuentas/shared/widgets/manage_list_scaffold.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

/// Ajustes → Contactos: ver, crear y editar.
/// pantalla → contactsProvider → CatalogsRepository → catalogos/contactos.php
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(
      hasPermissionProvider(Permissions.manageCatalogs),
    );
    return ManageListScaffold(
      title: 'Contactos',
      state: ref.watch(contactsProvider),
      onRetry: () => ref.invalidate(contactsProvider),
      emptyTitle: 'Sin contactos',
      emptyMessage: 'Crea a las personas con las que tienes acuerdos.',
      createTooltip: 'Nuevo contacto',
      onCreate: canManage ? () => showContactDialog(context) : null,
      itemBuilder: (context, contact) => ManageTile(
        key: ValueKey('contact-${contact.id}'),
        title: contact.name,
        icon: contact.iconData,
        tint: contact.tint,
        subtitle: contact.phone,
        inactive: !contact.active,
        onTap: canManage
            ? () => showContactDialog(context, contact: contact)
            : null,
      ),
    );
  }
}
