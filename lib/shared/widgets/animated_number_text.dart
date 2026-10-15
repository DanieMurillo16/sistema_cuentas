import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';

/// Una cifra que **cuenta** hasta su valor al aparecer y **se desliza** del
/// valor anterior al nuevo cuando cambia (un abono, un cambio de sucursal), en
/// vez de parpadear. Con [obscured] muestra [mask]; al destaparla vuelve a
/// contar desde cero, que es lo que hace sentir que "llega" la cifra.
class AnimatedNumberText extends StatelessWidget {
  const AnimatedNumberText({
    super.key,
    required this.value,
    this.style,
    this.obscured = false,
    this.formatter = formatCop,
  });

  final double value;
  final TextStyle? style;
  final bool obscured;

  /// Cómo se escribe el número (pesos, gramos, cantidades).
  final String Function(num) formatter;

  static const String mask = '••••••';

  @override
  Widget build(BuildContext context) {
    if (obscured) {
      return Semantics(
        label: 'Monto oculto',
        excludeSemantics: true,
        child: Text(mask, style: style),
      );
    }
    return Semantics(
      // El lector dice el valor final, no la cuenta mientras anima.
      label: formatter(value),
      excludeSemantics: true,
      child: _CountingText(value: value, formatter: formatter, style: style),
    );
  }
}

class _CountingText extends StatelessWidget {
  const _CountingText({
    required this.value,
    required this.formatter,
    required this.style,
  });

  final double value;
  final String Function(num) formatter;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Sin key: al cambiar `value` anima desde lo que se ve hasta el nuevo
      // valor. Al destapar, el widget es nuevo y cuenta desde 0.
      tween: Tween<double>(begin: 0, end: value),
      duration: motionDuration(context, DesignTokens.animationNumber),
      curve: DesignTokens.curve,
      // Una cifra nunca se parte en dos líneas ni se corta con «…»: si no
      // cabe, se encoge.
      builder: (context, current, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          formatter(current),
          maxLines: 1,
          softWrap: false,
          style: style,
        ),
      ),
    );
  }
}
