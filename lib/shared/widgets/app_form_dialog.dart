import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

/// Diálogo con un formulario: encabezado, campos en columna y el pie con
/// Cancelar y el botón que guarda. Mientras guarda no se puede cerrar (ni con
/// la X, ni con atrás) y el botón muestra progreso.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.formKey,
    required this.loading,
    required this.confirmLabel,
    required this.onConfirm,
    required this.children,
    this.subtitle,
    this.secondaryAction,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final GlobalKey<FormState> formKey;
  final bool loading;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final List<Widget> children;

  /// Una acción más en el pie, entre Cancelar y el botón principal.
  final Widget? secondaryAction;

  /// Otra operación (p. ej. eliminar) está en curso: no se puede cerrar ni
  /// pulsar nada, pero el progreso no sale en el botón principal.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading && !locked,
      child: AppDialog(
        header: DialogHeader(
          icon: icon,
          title: title,
          subtitle: subtitle,
          closeEnabled: !loading && !locked,
          onClose: () => Navigator.of(context).pop(),
        ),
        content: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const SizedBox(height: DesignTokens.spaceMd),
                child,
              ],
            ],
          ),
        ),
        actions: DialogActions(
          confirmLabel: confirmLabel,
          isLoading: loading,
          locked: locked,
          onConfirm: onConfirm,
          secondaryAction: secondaryAction,
        ),
      ),
    );
  }
}
