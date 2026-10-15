import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/contact_draft.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method_draft.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/contacts_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escrituras de los catálogos. Cada una actualiza su lista compartida y, como
/// el nombre aparece en movimientos, vencimientos, acuerdos y resumen, vuelve a
/// pedir esas pantallas (que conservan lo que muestran mientras llega).
final saveCategoryProvider =
    AsyncNotifierProvider.autoDispose<SaveCategoryNotifier, void>(
      SaveCategoryNotifier.new,
    );

final deleteCategoryProvider =
    AsyncNotifierProvider.autoDispose<DeleteCategoryNotifier, void>(
      DeleteCategoryNotifier.new,
    );

final savePaymentMethodProvider =
    AsyncNotifierProvider.autoDispose<SavePaymentMethodNotifier, void>(
      SavePaymentMethodNotifier.new,
    );

final saveContactProvider =
    AsyncNotifierProvider.autoDispose<SaveContactNotifier, void>(
      SaveContactNotifier.new,
    );

/// Un nombre cambiado aparece en movimientos, vencimientos, acuerdos y resumen:
/// solo al **editar** hay algo que ya se muestra y quedó viejo (crear no cambia
/// nada de lo existente).
void _refreshDependents(Ref ref, {required bool edited}) {
  if (!edited) return;
  ref.invalidate(movementsProvider);
  ref.invalidate(duesProvider);
  ref.invalidate(recurringListProvider);
  ref.invalidate(monthSummaryProvider);
}

class SaveCategoryNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(CategoryDraft draft) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final saved = await ref
            .read(catalogsRepositoryProvider)
            .saveCategory(draft);
        ref.read(categoriesProvider.notifier).upsert(saved);
        _refreshDependents(ref, edited: draft.id != null);
      });
    } finally {
      keepAlive.close();
    }
  }
}

/// Elimina una categoría. Nada ya registrado cambia (el nombre sigue igual), así
/// que no hay otras pantallas que volver a pedir: solo se marca en la lista.
class DeleteCategoryNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> delete(int id) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        await ref.read(catalogsRepositoryProvider).deleteCategory(id);
        ref.read(categoriesProvider.notifier).markDeleted(id);
      });
    } finally {
      keepAlive.close();
    }
  }
}

class SavePaymentMethodNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(PaymentMethodDraft draft) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final saved = await ref
            .read(catalogsRepositoryProvider)
            .savePaymentMethod(draft);
        ref.read(paymentMethodsProvider.notifier).upsert(saved);
        _refreshDependents(ref, edited: draft.id != null);
      });
    } finally {
      keepAlive.close();
    }
  }
}

class SaveContactNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(ContactDraft draft) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final saved = await ref
            .read(catalogsRepositoryProvider)
            .saveContact(draft);
        ref.read(contactsProvider.notifier).upsert(saved);
        _refreshDependents(ref, edited: draft.id != null);
      });
    } finally {
      keepAlive.close();
    }
  }
}
