import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';

/// Muestra u oculta un bloque **creciendo/encogiéndose con fundido** (paneles
/// plegables, detalles, avisos en línea), en vez de que el resto de la pantalla
/// salte.
class AppCollapse extends StatelessWidget {
  const AppCollapse({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, DesignTokens.animationNormal);
    // Con «reducir movimiento» el cambio es inmediato: AnimatedSize con
    // duración cero lanza una aserción en debug.
    if (duration == Duration.zero) {
      return visible ? child : const SizedBox(width: double.infinity);
    }
    return AnimatedSize(
      duration: duration,
      curve: DesignTokens.curve,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: duration,
        opacity: visible ? 1 : 0,
        child: visible ? child : const SizedBox(width: double.infinity),
      ),
    );
  }
}
