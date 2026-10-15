import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/category_draft.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/initial_balance/models/initial_balance_entry.dart';
import 'package:sistema_cuentas/features/initial_balance/utils/initial_balance_rules.dart';
import 'package:sistema_cuentas/features/movements/data/movements_repository.dart';
import 'package:sistema_cuentas/features/movements/models/movement_draft.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';

/// Escritura: registrar el saldo inicial. Usa la categoría «Saldo inicial» (de
/// capital; si no existe la crea) y registra un ingreso por cada medio de pago
/// con valor. Si algo falla a mitad, lo que ya quedó registrado se ve en el
/// historial y **no se repite** al reintentar mientras el diálogo siga abierto.
final saveInitialBalanceProvider =
    AsyncNotifierProvider.autoDispose<SaveInitialBalanceNotifier, void>(
      SaveInitialBalanceNotifier.new,
    );

class SaveInitialBalanceNotifier extends AsyncNotifier<void> {
  // Medios que ya quedaron registrados en este intento (no se repiten).
  final _done = <int>{};

  @override
  void build() {}

  Future<void> save(List<InitialBalanceEntry> entries) async {
    if (state.isLoading) return; // anti doble envío (no solo el botón)
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final category = await _category();
        final repository = ref.read(movementsRepositoryProvider);
        for (final entry in entries) {
          if (_done.contains(entry.methodId)) continue;
          final movement = await repository.register(
            MovementDraft(
              type: MovementType.income,
              amountPesos: entry.pesos,
              date: dateOnly(DateTime.now()),
              description: InitialBalanceRules.description,
              categoryId: category.id,
              methodId: entry.methodId,
            ),
          );
          _done.add(entry.methodId);
          ref.read(movementsProvider.notifier).upsert(movement);
        }
        ref.invalidate(monthSummaryProvider);
      });
    } finally {
      keepAlive.close();
    }
  }

  /// La categoría «Saldo inicial» de ingresos; la crea (de capital) si no hay.
  Future<Category> _category() async {
    final categories = await ref.read(categoriesProvider.future);
    final existing = categories.where(
      (c) =>
          c.type.isIncome &&
          c.active &&
          c.name.trim().toLowerCase() ==
              InitialBalanceRules.categoryName.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;
    final created = await ref
        .read(catalogsRepositoryProvider)
        .saveCategory(
          const CategoryDraft(
            type: MovementType.income,
            name: InitialBalanceRules.categoryName,
            isCapital: true,
            active: true,
          ),
        );
    ref.read(categoriesProvider.notifier).upsert(created);
    return created;
  }
}
