import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_tip_provider.dart';
import 'package:sistema_cuentas/features/auth/utils/splash_tips.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';

/// El mensaje de la pantalla de carga con su icono en un cuadro de color; cambia con un fundido y
/// abajo unos puntos dicen cuál es de cuántos.
class SplashTipView extends ConsumerWidget {
  const SplashTipView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Con «reducir movimiento» el mensaje no cambia solo: se queda el primero.
    final still = MediaQuery.disableAnimationsOf(context);
    final index = still ? 0 : ref.watch(splashTipIndexProvider).value ?? 0;
    final tip = splashTips[index];
    final textTheme = Theme.of(context).textTheme;
    return ExcludeSemantics(
      // El lector anuncia «Cargando» (ver `SplashContent`); los mensajes que
      // cambian solos serían ruido.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alto mínimo reservado: el logo y la barra no saltan al cambiar.
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DesignTokens.splashTipMinHeight,
            ),
            child: AnimatedSwitcher(
              duration: motionDuration(context, DesignTokens.animationNormal),
              transitionBuilder: _pop,
              child: Column(
                key: ValueKey(index),
                mainAxisSize: MainAxisSize.min,
                children: [
                  CatalogBadge(
                    icon: tip.icon,
                    color: AppColors.accent,
                    size: DesignTokens.splashBadgeSize,
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(
                    tip.text,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < splashTips.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceXs,
                  ),
                  child: _Dot(active: i == index),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Entra con fundido y creciendo un poco (de 85 % a 100 %); el anterior sale
/// con el fundido. Sin rebote.
Widget _pop(Widget child, Animation<double> animation) => FadeTransition(
  opacity: animation,
  child: ScaleTransition(
    scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
    child: child,
  ),
);

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: motionDuration(context, DesignTokens.animationFast),
      width: active
          ? DesignTokens.splashDotActiveWidth
          : DesignTokens.splashDotSize,
      height: DesignTokens.splashDotSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        color: active ? AppColors.accent : AppColors.inputBorder,
      ),
    );
  }
}
