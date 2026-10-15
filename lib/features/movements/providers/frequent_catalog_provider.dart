import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/frequent_rules.dart';

/// Las categorías más usadas (activas, del tipo dado) en los movimientos del
/// mes que se ve. Se derivan de `movementsProvider`: no hay una lista aparte.
final frequentCategoriesProvider =
    Provider.family<List<Category>, MovementType>((ref, type) {
      final ids = FrequentRules.topIds([
        for (final m in ref.watch(movementsProvider).value ?? const [])
          if (m.type == type) m.categoryId,
      ]);
      final items =
          ref.watch(categoriesForTypeProvider(type)).value ?? const [];
      return [
        for (final id in ids)
          for (final c in items)
            if (c.id == id) c,
      ];
    });

/// Los medios de pago activos más usados en los movimientos del mes que se ve.
final frequentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final ids = FrequentRules.topIds([
    for (final m in ref.watch(movementsProvider).value ?? const []) m.methodId,
  ]);
  final items = ref.watch(activePaymentMethodsProvider).value ?? const [];
  return [
    for (final id in ids)
      for (final m in items)
        if (m.id == id) m,
  ];
});
