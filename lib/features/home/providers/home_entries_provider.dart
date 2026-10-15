import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Qué ve el historial de Inicio: todo (`null`), solo ingresos o solo gastos.
/// Filtra lo ya cargado, sin red.
final homeTypeFilterProvider =
    NotifierProvider.autoDispose<HomeTypeFilterNotifier, MovementType?>(
      HomeTypeFilterNotifier.new,
    );

class HomeTypeFilterNotifier extends Notifier<MovementType?> {
  @override
  MovementType? build() {
    // Otra cuenta empieza viendo todo.
    ref.watch(sessionUserIdProvider);
    return null;
  }

  void set(MovementType? type) => state = type;
}

/// Las líneas de Inicio (días y movimientos) derivadas de la lista del mes y
/// del filtro. Nada se guarda aparte: si la lista cambia, esto cambia.
final homeEntriesProvider = Provider<List<MovementEntry>>((ref) {
  final movements = ref.watch(movementsProvider).value ?? const [];
  final type = ref.watch(homeTypeFilterProvider);
  return buildDayEntries(filterByType(movements, type), today: DateTime.now());
});
