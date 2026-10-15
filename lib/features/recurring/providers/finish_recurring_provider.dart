import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escritura: finalizar un pago recurrente (irreversible). Lo pendiente queda
/// anulado y, si se registró capital, aparece un movimiento nuevo: por eso se
/// vuelve a pedir la lista, el detalle, los vencimientos, el historial y el
/// resumen.
final finishRecurringProvider =
    AsyncNotifierProvider.autoDispose<FinishRecurringNotifier, void>(
      FinishRecurringNotifier.new,
    );

class FinishRecurringNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> finish(FinishDraft draft) async {
    if (state.isLoading) return;
    // Si se cierra la pantalla mientras guarda, la escritura termina y la app
    // se entera igual (el servidor ya la registró).
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        await ref.read(recurringRepositoryProvider).finish(draft);
        ref.invalidate(recurringListProvider);
        ref.invalidate(recurringDetailProvider(draft.recurringId));
        ref.invalidate(duesProvider);
        ref.invalidate(movementsProvider);
        ref.invalidate(monthSummaryProvider);
      });
    } finally {
      keepAlive.close();
    }
  }
}
