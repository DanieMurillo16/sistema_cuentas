import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/movements/widgets/day_header_tile.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_cancel_dialog.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_tile.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';

/// El historial por día como lista por demanda: cada línea conserva su
/// `ValueKey`, así que al agregar o quitar un movimiento solo cambia esa fila.
/// Quien puede anular movimientos (`movimientos.anular`) desliza una fila a la
/// izquierda para eliminarla.
class MovementEntriesSliver extends ConsumerWidget {
  const MovementEntriesSliver({
    super.key,
    required this.entries,
    required this.hidden,
  });

  final List<MovementEntry> entries;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel = ref.watch(
      hasPermissionProvider(Permissions.cancelMovements),
    );
    return SliverList.builder(
      itemCount: entries.length,
      // Al quitar una fila, las de abajo conservan su estado (se buscan por
      // su llave, no por su posición).
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        final index = entries.indexWhere((e) => _keyOf(e) == key.value);
        return index < 0 ? null : index;
      },
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          DayHeaderEntry() => DayHeaderTile(
            key: ValueKey(_keyOf(entry)),
            entry: entry,
            hidden: hidden,
          ),
          MovementRowEntry() => MovementTile(
            key: ValueKey(_keyOf(entry)),
            movement: entry.movement,
            position: entry.position,
            hidden: hidden,
            onConfirmCancel: canCancel
                ? () => confirmCancelMovement(context, entry.movement)
                : null,
          ),
        };
      },
    );
  }

  static String _keyOf(MovementEntry entry) => switch (entry) {
    DayHeaderEntry() => 'day-${entry.date.toIso8601String()}',
    MovementRowEntry() => 'movement-${entry.movement.id}',
  };
}
