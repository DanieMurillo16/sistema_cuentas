import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';

/// Página que entra (y sale) con un fundido, sin deslizar: para pasar del splash
/// al login o a Inicio, y del login a Inicio, de forma suave y limpia. Con
/// «reducir movimiento» el cambio es inmediato.
CustomTransitionPage<void> fadePage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final duration = motionDuration(context, DesignTokens.animationRoute);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: DesignTokens.curve,
          ),
          child: child,
        ),
  );
}
