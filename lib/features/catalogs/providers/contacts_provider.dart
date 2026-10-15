import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Contactos de la sesión (activos e inactivos) (quién me paga, a quién le pago).
final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<Contact>>(
  ContactsNotifier.new,
);

/// Los contactos que se pueden elegir al crear algo (los activos).
final activeContactsProvider = Provider<AsyncValue<List<Contact>>>(
  (ref) => mapKeepingData(
    ref.watch(contactsProvider),
    (items) => [
      for (final item in items)
        if (item.active) item,
    ],
  ),
);

class ContactsNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() {
    ref.watch(sessionUserIdProvider);
    return ref.read(catalogsRepositoryProvider).contacts();
  }

  void upsert(Contact contact) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((c) => c.id == contact.id);
    final merged = [
      for (final c in current)
        if (c.id == contact.id) contact else c,
      if (!exists) contact,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    state = AsyncData(merged);
  }
}
