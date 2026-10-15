import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escritura: registrar un movimiento suelto. Al terminar bien actualiza la
/// lista del mes (se ve ya) y vuelve a pedir el resumen (el servidor es la
/// fuente de los saldos; la pantalla conserva lo que muestra mientras llega).
final saveMovementProvider =
    AsyncNotifierProvider.autoDispose<SaveMovementNotifier, void>(
      SaveMovementNotifier.new,
    );

class SaveMovementNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(MovementDraft draft) async {
    if (state.isLoading) return; // anti doble envío (no solo el botón)
    // Si se cierra la pantalla mientras guarda, la escritura termina y la app
    // se entera igual (el servidor ya la registró).
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final movement = await ref
            .read(movementsRepositoryProvider)
            .register(draft);
        ref.read(movementsProvider.notifier).upsert(movement);
        ref.invalidate(monthSummaryProvider);
      });
    } finally {
      keepAlive.close();
    }
  }
}
