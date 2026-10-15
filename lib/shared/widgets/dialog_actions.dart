import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

import 'dialog_action_bar.dart';

class DialogActions extends StatelessWidget {
  const DialogActions({
    super.key,
    required this.onConfirm,
    required this.confirmLabel,
    this.isLoading = false,
    this.locked = false,
    this.onCancel,
    this.destructive = false,
    this.confirmIcon = Icons.save_outlined,
    this.showCancel = true,
    this.cancelLabel = 'Cancelar',
    this.secondaryAction,
  });

  final VoidCallback? onConfirm;
  final String confirmLabel;
  final bool isLoading;

  /// Otra operación está en curso (no es guardar): bloquea los botones sin
  /// poner el progreso en el principal.
  final bool locked;
  final VoidCallback? onCancel;
  final bool destructive;
  final IconData? confirmIcon;
  final bool showCancel;
  final String cancelLabel;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && !locked && onConfirm != null;
    return DialogActionBar(
      children: [
        if (showCancel)
          OutlinedButton(
            onPressed: isLoading || locked
                ? null
                : onCancel ?? () => Navigator.of(context).pop(),
            child: Text(cancelLabel),
          ),
        ?secondaryAction,
        FilledButton.icon(
          onPressed: enabled ? onConfirm : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, DesignTokens.dialogButtonHeight),
            backgroundColor: destructive
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          icon: isLoading
              ? const SizedBox.square(
                  dimension: DesignTokens.progressSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(confirmIcon),
          label: Text(confirmLabel),
        ),
      ],
    );
  }
}
