import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';

/// Los movimientos de una categoría en el mes elegido: salen de la lista de
/// Inicio, que ya está cargada (no hay petición nueva). Más reciente primero.
final categoryMovementsProvider =
    Provider.family<List<Movement>, ({int categoryId, MovementType type})>((
      ref,
      key,
    ) {
      final all = ref.watch(movementsProvider).value ?? const <Movement>[];
      return [
        for (final m in all)
          if (m.categoryId == key.categoryId && m.type == key.type) m,
      ];
    });
