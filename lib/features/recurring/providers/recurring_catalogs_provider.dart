import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';

/// Las categorías que acepta un pago recurrente: activas, del mismo tipo y
/// **no** de capital (el servidor las rechaza).
final recurringCategoriesProvider =
    Provider.family<AsyncValue<List<Category>>, MovementType>(
      (ref, type) => mapKeepingData(
        ref.watch(categoriesForTypeProvider(type)),
        (items) => [
          for (final item in items)
            if (!item.isCapital) item,
        ],
      ),
    );
