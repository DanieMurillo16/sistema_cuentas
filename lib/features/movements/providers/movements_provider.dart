import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Los movimientos vigentes del mes elegido en la cabecera. Es el único lugar
/// donde vive esa lista: Inicio, buscador y totales del día se derivan de aquí.
/// Al cambiar de mes o de cuenta se vuelve a pedir, conservando lo que se ve
/// mientras llega la respuesta.
final movementsProvider =
    AsyncNotifierProvider<MovementsNotifier, List<Movement>>(
      MovementsNotifier.new,
    );

class MovementsNotifier extends AsyncNotifier<List<Movement>> {
  @override
  Future<List<Movement>> build() async {
    ref.watch(sessionUserIdProvider);
    final month = ref.watch(selectedMonthProvider);
    final items = await ref
        .read(movementsRepositoryProvider)
        .listBetween(from: month, to: lastDayOfMonth(month));
    return sortMovements(items);
  }

  /// Agrega o reemplaza un movimiento si cae dentro del mes que se muestra.
  void upsert(Movement movement) {
    final current = state.value;
    if (current == null) return;
    final month = ref.read(selectedMonthProvider);
    if (movement.date.year != month.year ||
        movement.date.month != month.month) {
      return;
    }
    state = AsyncData(
      sortMovements([
        for (final m in current)
          if (m.id != movement.id) m,
        movement,
      ]),
    );
  }

  /// Quita un movimiento anulado de la lista vigente.
  void remove(int id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final m in current)
        if (m.id != id) m,
    ]);
  }
}
