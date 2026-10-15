import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Categorías de la sesión (activas e inactivas; los selectores filtran). Se cargan una vez y las usan el formulario,
/// los filtros y (luego) Ajustes, que las actualiza con [upsert].
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
      CategoriesNotifier.new,
    );

/// Una categoría por su id (para pintar su icono y color en una fila). `null`
/// mientras cargan o si ya no existe. Solo se reconstruye quien mira esa.
final categoryByIdProvider = Provider.family<Category?, int>(
  (ref, id) => ref.watch(
    categoriesProvider.select(
      (async) => async.value?.where((c) => c.id == id).firstOrNull,
    ),
  ),
);

/// Las categorías que se listan en Ajustes: las inactivas sí (se pueden volver a
/// activar), las eliminadas no.
final visibleCategoriesProvider = Provider<AsyncValue<List<Category>>>(
  (ref) => mapKeepingData(
    ref.watch(categoriesProvider),
    (items) => [
      for (final item in items)
        if (!item.deleted) item,
    ],
  ),
);

/// Todas las categorías de un tipo, también las inactivas: sirven para filtrar
/// el historial (un movimiento viejo puede ser de una categoría ya apagada).
final categoriesOfTypeProvider =
    Provider.family<AsyncValue<List<Category>>, MovementType>(
      (ref, type) => mapKeepingData(
        ref.watch(categoriesProvider),
        (items) => [
          for (final item in items)
            if (item.type == type) item,
        ],
      ),
    );

/// Las categorías que se pueden elegir para un ingreso o un gasto.
final categoriesForTypeProvider =
    Provider.family<AsyncValue<List<Category>>, MovementType>(
      (ref, type) => mapKeepingData(
        ref.watch(categoriesProvider),
        (items) => [
          for (final item in items)
            if (item.type == type && item.active) item,
        ],
      ),
    );

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() {
    ref.watch(sessionUserIdProvider);
    return ref.read(catalogsRepositoryProvider).categories();
  }

  void upsert(Category category) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((c) => c.id == category.id);
    final merged = [
      for (final c in current)
        if (c.id == category.id) category else c,
      if (!exists) category,
    ];
    // Ingresos primero y, dentro de cada tipo, por nombre.
    merged.sort((a, b) {
      final byType = a.type.index.compareTo(b.type.index);
      return byType != 0
          ? byType
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    state = AsyncData(merged);
  }

  /// Una categoría eliminada se queda en la lista (con `deleted`) para que lo
  /// registrado con ella siga pintando su icono y su color.
  void markDeleted(int id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final c in current)
        if (c.id == id) c.asDeleted() else c,
    ]);
  }
}
