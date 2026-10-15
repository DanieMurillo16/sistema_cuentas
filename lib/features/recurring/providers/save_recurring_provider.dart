import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';

/// Escritura: crear un pago recurrente. Lo agrega a la lista compartida y
/// vuelve a pedir los vencimientos (el servidor genera los del mes al crearlo).
final saveRecurringProvider =
    AsyncNotifierProvider.autoDispose<SaveRecurringNotifier, void>(
      SaveRecurringNotifier.new,
    );

class SaveRecurringNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(RecurringDraft draft) async {
    if (state.isLoading) return;
    // Si se cierra la pantalla mientras guarda, la escritura termina y la app
    // se entera igual (el servidor ya la registró).
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final payment = await ref
            .read(recurringRepositoryProvider)
            .create(draft);
        ref.read(recurringListProvider.notifier).upsert(payment);
        ref.invalidate(duesProvider);
      });
    } finally {
      keepAlive.close();
    }
  }
}
