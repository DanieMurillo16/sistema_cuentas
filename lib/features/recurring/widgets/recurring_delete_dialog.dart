import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/recurring/providers/delete_recurring_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/utils/listen_save.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

/// Pregunta si eliminar el pago recurrente [recurringId] y, si se confirma, lo
/// hace. `true` si quedó eliminado; `false` si se canceló o falló (el aviso del
/// error ya salió).
Future<bool> confirmDeleteRecurring(
  BuildContext context, {
  required int recurringId,
  required String name,
  required bool isIncome,
}) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => RecurringDeleteDialog(
      recurringId: recurringId,
      name: name,
      isIncome: isIncome,
    ),
  );
  return done ?? false;
}

/// Confirmación de eliminar un pago recurrente: solo pregunta, sin motivo (la
/// nota que pide el servidor la pone la app). Mientras elimina no se cierra.
class RecurringDeleteDialog extends ConsumerStatefulWidget {
  const RecurringDeleteDialog({
    super.key,
    required this.recurringId,
    required this.name,
    required this.isIncome,
  });

  final int recurringId;
  final String name;
  final bool isIncome;

  @override
  ConsumerState<RecurringDeleteDialog> createState() =>
      _RecurringDeleteDialogState();
}

class _RecurringDeleteDialogState extends ConsumerState<RecurringDeleteDialog> {
  @override
  void initState() {
    super.initState();
    listenSave(
      ref,
      deleteRecurringProvider,
      successMessage: 'Pago recurrente eliminado',
      onSuccess: () {
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      deleteRecurringProvider.select((s) => s.isLoading),
    );
    return PopScope(
      canPop: !loading,
      child: AppDialog(
        header: DialogHeader(
          icon: Icons.delete_outline_rounded,
          color: AppColors.expense,
          title: 'Eliminar pago recurrente',
          subtitle: formatDisplayText(widget.name),
          closeEnabled: !loading,
          onClose: () => Navigator.of(context).pop(false),
        ),
        content: Text(
          '${RecurringRules.deleteQuestion(widget.name)} '
          '${RecurringRules.deleteConsequence(isIncome: widget.isIncome)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: DialogActions(
          confirmLabel: 'Eliminar',
          confirmIcon: Icons.delete_outline_rounded,
          destructive: true,
          isLoading: loading,
          onConfirm: () => ref
              .read(deleteRecurringProvider.notifier)
              .delete(widget.recurringId),
        ),
      ),
    );
  }
}
