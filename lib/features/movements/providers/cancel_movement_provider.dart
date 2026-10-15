import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escritura: eliminar (anular con motivo) un movimiento. Al terminar bien la
/// fila sale de las listas que se ven y se vuelve a pedir lo que quedó viejo:
/// el resumen, y —si era un pago o abono de un acuerdo— los vencimientos y el
/// acuerdo.
final cancelMovementProvider =
    AsyncNotifierProvider.autoDispose<CancelMovementNotifier, void>(
      CancelMovementNotifier.new,
    );

class CancelMovementNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> cancel(Movement movement, {required String reason}) async {
    if (state.isLoading) return; // anti doble envío (no solo el botón)
    // Si se cierra el diálogo mientras guarda, la anulación termina y la app
    // se entera igual (el servidor ya la hizo).
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        await ref
            .read(movementsRepositoryProvider)
            .cancel(movement.id, reason: reason.trim());
        // Sin lista cargada no hay de dónde quitarla: se vuelve a pedir.
        if (ref.read(movementsProvider).hasValue) {
          ref.read(movementsProvider.notifier).remove(movement.id);
        } else {
          ref.invalidate(movementsProvider);
        }
        final list = movementsListProvider(movement.type);
        if (ref.exists(list)) {
          if (ref.read(list).hasValue) {
            ref.read(list.notifier).remove(movement.id);
          } else {
            ref.invalidate(list);
          }
        }
        ref.invalidate(monthSummaryProvider);
        if (movement.fromRecurring) {
          ref.invalidate(duesProvider);
          ref.invalidate(recurringListProvider);
          ref.invalidate(recurringDetailProvider);
        }
      });
    } finally {
      keepAlive.close();
    }
  }
}
