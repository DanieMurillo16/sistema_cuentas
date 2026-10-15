import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Deslizar una fila hacia la izquierda para eliminarla: aparece un fondo rojo
/// con el bote de basura y se pide [onConfirm], que devuelve `true` si quedó
/// eliminada. Sin [onConfirm] la fila no se desliza.
///
/// La fila sale de la lista cuando el provider confirma el cambio; este widget
/// no la quita. Quien lo use recorta las esquinas (`ClipRRect`) si la fila las
/// tiene redondeadas.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.itemKey,
    required this.onConfirm,
    required this.child,
  });

  /// Identifica la fila (por ejemplo `movement-12`).
  final String itemKey;
  final Future<bool> Function()? onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final confirm = onConfirm;
    if (confirm == null) return child;
    return Dismissible(
      key: ValueKey('swipe-$itemKey'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      confirmDismiss: (_) => confirm(),
      onDismissed: (_) {},
      child: child,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.error,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Icon(Icons.delete_outline_rounded, color: AppColors.onBrand),
        ),
      ),
    );
  }
}
