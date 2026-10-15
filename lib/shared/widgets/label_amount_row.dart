import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// «Etiqueta … monto» en una fila: el texto ocupa **todo lo que el monto no
/// necesite** y el monto mide lo suyo (hasta [maxAmountFactor] de la fila, y si
/// aun así no cabe se encoge, nunca se parte).
///
/// Evita el reparto 50/50 de `Expanded` + `Flexible` hermanos, que dejaba al
/// nombre con la mitad del ancho aunque el monto fuera corto.
class LabelAmountRow extends StatelessWidget {
  const LabelAmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.leading,
    this.trailing,
    this.maxAmountFactor = 0.5,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// El texto de la izquierda (puede crecer a varias líneas).
  final Widget label;

  /// El monto (un `Text`); se alinea a la derecha y se encoge si hace falta.
  final Widget amount;

  /// Algo fijo antes de la etiqueta (un punto de color, un icono).
  final Widget? leading;

  /// Algo fijo después del monto (una flecha).
  final Widget? trailing;

  /// Cuánto de la fila puede ocupar el monto como máximo.
  final double maxAmountFactor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          ?leading,
          Expanded(child: label),
          const SizedBox(width: DesignTokens.spaceSm),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * maxAmountFactor,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: amount,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
