import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/features/movements/providers/cancel_movement_provider.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_cancel_rules.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

/// Pregunta si eliminar [movement] y, si se confirma, lo hace. `true` si quedó
/// eliminado; `false` si se canceló o falló (el aviso del error ya salió).
Future<bool> confirmCancelMovement(
  BuildContext context,
  Movement movement,
) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => MovementCancelDialog(movement: movement),
  );
  return done ?? false;
}

/// Confirmación de eliminar un movimiento: solo pregunta; el motivo que exige
/// el servidor lo pone la app. Mientras elimina no se puede cerrar y el botón muestra progreso.
class MovementCancelDialog extends ConsumerStatefulWidget {
  const MovementCancelDialog({super.key, required this.movement});

  final Movement movement;

  @override
  ConsumerState<MovementCancelDialog> createState() =>
      _MovementCancelDialogState();
}

class _MovementCancelDialogState extends ConsumerState<MovementCancelDialog> {
  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      cancelMovementProvider,
      successMessage: 'Movimiento eliminado',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  void _confirm() => ref
      .read(cancelMovementProvider.notifier)
      .cancel(widget.movement, reason: MovementCancelRules.reason);

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      cancelMovementProvider.select((s) => s.isLoading),
    );
    final movement = widget.movement;
    return PopScope(
      canPop: !loading,
      child: AppDialog(
        header: DialogHeader(
          icon: Icons.delete_outline_rounded,
          color: AppColors.expense,
          title: MovementCancelRules.title(movement),
          subtitle: MovementCancelRules.subtitle(movement),
          closeEnabled: !loading,
          onClose: () => Navigator.of(context).pop(false),
        ),
        content: Text(
          movement.isIncome
              ? '¿Eliminar este ingreso? Dejará de contar en tus saldos.'
              : '¿Eliminar este gasto? Dejará de contar en tus saldos.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: DialogActions(
          confirmLabel: 'Eliminar',
          confirmIcon: Icons.delete_outline_rounded,
          destructive: true,
          isLoading: loading,
          onConfirm: _confirm,
        ),
      ),
    );
  }
}
