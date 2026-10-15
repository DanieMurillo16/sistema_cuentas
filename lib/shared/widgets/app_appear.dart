import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';

/// Entrada suave (fundido + deslizamiento corto) para lo que **aparece**: una
/// tarjeta nueva, un resultado. Solo anima al montarse; si el dato cambia pero
/// el widget sigue (misma `ValueKey(id)`), no vuelve a animar.
class AppAppear extends StatelessWidget {
  const AppAppear({super.key, required this.child});

  final Widget child;

  static const double _offset = 8;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: motionDuration(context, DesignTokens.animationNormal),
    curve: DesignTokens.curve,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * _offset),
        child: child,
      ),
    ),
  );
}
