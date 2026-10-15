import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escritura: eliminar un pago recurrente («ya no lo quiero ver»). En el
/// servidor nada se borra: el acuerdo queda finalizado y todo lo que no tenga
/// pagos (también lo vencido) se anula; lo ya pagado se conserva. Al terminar
/// bien, el acuerdo y sus vencimientos salen de lo que se ve y se vuelve a pedir
/// lo que quedó viejo.
final deleteRecurringProvider =
    AsyncNotifierProvider.autoDispose<DeleteRecurringNotifier, void>(
      DeleteRecurringNotifier.new,
    );

class DeleteRecurringNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> delete(int recurringId) async {
    if (state.isLoading) return; // anti doble envío (no solo el botón)
    // Si se cierra el diálogo mientras guarda, termina y la app se entera igual.
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        await ref.read(recurringRepositoryProvider).delete(recurringId);
        ref.read(recurringListProvider.notifier).remove(recurringId);
        ref.read(duesProvider.notifier).removeByRecurring(recurringId);
        ref.invalidate(recurringListProvider);
        ref.invalidate(recurringDetailProvider(recurringId));
        ref.invalidate(duesProvider);
        ref.invalidate(movementsProvider);
        ref.invalidate(monthSummaryProvider);
      });
    } finally {
      keepAlive.close();
    }
  }
}
