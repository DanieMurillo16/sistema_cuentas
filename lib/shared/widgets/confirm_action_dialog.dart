import 'package:flutter/material.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

class ConfirmActionDialog extends StatelessWidget {
  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AppDialog(
      header: DialogHeader(
        icon: icon,
        title: title,
        subtitle: 'Confirmación requerida',
        color: errorColor,
        onClose: () => Navigator.of(context).pop(false),
      ),
      content: Text(message),
      actions: DialogActions(
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmIcon: icon,
        destructive: true,
      ),
    );
  }
}
