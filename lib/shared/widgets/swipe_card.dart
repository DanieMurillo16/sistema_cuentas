import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/swipe_to_delete.dart';

/// Tarjeta (borde tenue y esquinas redondeadas) que se desliza a la izquierda
/// para eliminar. El borde y las esquinas se quedan quietos y lo de dentro se
/// desliza plano sobre el fondo rojo, como las filas del historial de Inicio;
/// una `Card` que se deslizara entera mostraría sus esquinas y su borde
/// recortados contra el fondo.
class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.itemKey,
    required this.onConfirm,
    required this.child,
  });

  final String itemKey;
  final Future<bool> Function()? onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignTokens.radiusLg);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SwipeToDelete(
          itemKey: itemKey,
          onConfirm: onConfirm,
          // Material (no ColoredBox): la salpicadura del toque se ve y viaja
          // con la fila al deslizarla.
          child: Material(color: AppColors.surface, child: child),
        ),
      ),
    );
  }
}
