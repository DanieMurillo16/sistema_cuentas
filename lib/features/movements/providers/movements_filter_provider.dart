import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/models/movements_filter.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// El filtro de la lista de ingresos o de gastos (uno por tipo). Se descarta al
/// salir de la pantalla y empieza con el mes que se estaba viendo.
final movementsFilterProvider = NotifierProvider.autoDispose
    .family<MovementsFilterNotifier, MovementsFilter, MovementType>(
      MovementsFilterNotifier.new,
    );

class MovementsFilterNotifier extends Notifier<MovementsFilter> {
  MovementsFilterNotifier(this.type);

  final MovementType type;

  @override
  MovementsFilter build() =>
      MovementsFilter.forMonth(type, ref.read(selectedMonthProvider));

  void setRange(DateTimeRange range) => state = state.copyWith(range: range);

  void setQuery(String query) => state = state.copyWith(query: query);

  void setCategory(int? id) => state = id == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(categoryId: id);

  void setMethod(int? id) => state = id == null
      ? state.copyWith(clearMethod: true)
      : state.copyWith(methodId: id);

  /// Vuelve a todo el mes elegido, sin categoría, medio ni texto.
  void reset() =>
      state = MovementsFilter.forMonth(type, ref.read(selectedMonthProvider));
}

/// Los movimientos que pide el servidor con los filtros de fechas, categoría y
/// medio. Es un notifier (no una familia por consulta): al cambiar un filtro el
/// valor anterior sigue en pantalla mientras llega el nuevo, sin cargador de
/// página completa.
final movementsListProvider = AsyncNotifierProvider.autoDispose
    .family<MovementsListNotifier, List<Movement>, MovementType>(
      MovementsListNotifier.new,
    );

class MovementsListNotifier extends AsyncNotifier<List<Movement>> {
  MovementsListNotifier(this.type);

  final MovementType type;

  @override
  Future<List<Movement>> build() async {
    ref.watch(sessionUserIdProvider);
    final query = ref.watch(
      movementsFilterProvider(type).select((f) => f.serverQuery),
    );
    final items = await ref
        .read(movementsRepositoryProvider)
        .search(
          from: query.from,
          to: query.to,
          type: query.type,
          categoryId: query.categoryId,
          methodId: query.methodId,
        );
    return sortMovements(items);
  }

  /// Quita un movimiento anulado sin volver a pedir la lista.
  void remove(int id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final m in current)
        if (m.id != id) m,
    ]);
  }
}

/// Lo que se pinta: la respuesta del servidor y sobre ella la búsqueda por
/// texto (local, sin otra petición). Es un notifier que espera a
/// [movementsListProvider], así hereda su estado: mientras llega la respuesta
/// de un filtro nuevo sigue la lista anterior **y** la pantalla sabe que
/// recarga; si falla, avisa en vez de pasar por buena la lista vieja.
final filteredMovementsProvider = AsyncNotifierProvider.autoDispose
    .family<FilteredMovementsNotifier, List<Movement>, MovementType>(
      FilteredMovementsNotifier.new,
    );

class FilteredMovementsNotifier extends AsyncNotifier<List<Movement>> {
  FilteredMovementsNotifier(this.type);

  final MovementType type;

  @override
  Future<List<Movement>> build() async {
    final query = ref.watch(
      movementsFilterProvider(type).select((f) => f.query),
    );
    final items = await ref.watch(movementsListProvider(type).future);
    return filterMovements(items, query);
  }
}

/// Lo que suman los movimientos que se ven (en centavos).
final filteredTotalProvider = Provider.autoDispose.family<int, MovementType>(
  (ref, type) =>
      sumCents(ref.watch(filteredMovementsProvider(type)).value ?? const []),
);

/// Las líneas de la lista (días y movimientos) de lo que se ve.
final filteredEntriesProvider = Provider.autoDispose
    .family<List<MovementEntry>, MovementType>(
      (ref, type) => buildDayEntries(
        ref.watch(filteredMovementsProvider(type)).value ?? const [],
        today: DateTime.now(),
      ),
    );
