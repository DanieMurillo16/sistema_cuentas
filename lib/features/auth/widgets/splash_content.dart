import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/auth/widgets/splash_brand.dart';
import 'package:sistema_cuentas/features/auth/widgets/splash_tip_view.dart';

/// La pantalla de carga: el logo y el nombre en el centro (donde los deja el
/// arranque del sistema) y, debajo, los mensajes (que cambian solos). Arriba se
/// reserva lo mismo que ocupa lo de abajo, así el logo queda en el centro sin
/// medir nada; si la pantalla es muy baja (horizontal, texto grande) todo se
/// desplaza en vez de montarse o desbordar.
class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final reserve = MediaQuery.textScalerOf(context)
        .scale(DesignTokens.splashBelowReserve);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: reserve),
                  const SplashBrand(),
                  const _Below(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Los mensajes, con su margen.
class _Below extends StatelessWidget {
  const _Below();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DesignTokens.loginMaxWidth),
        // El lector de pantalla anuncia «Cargando» una sola vez (región viva);
        // a la vista solo están los mensajes: la app se presenta mientras abre.
        child: Semantics(
          liveRegion: true,
          container: true,
          label: 'Cargando',
          child: const SplashTipView(),
        ),
      ),
    );
  }
}
