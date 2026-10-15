import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/config/app_config.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/brand_logo.dart';

/// El logo y el nombre de la app: lo mismo, en el mismo lugar, que muestra el
/// sistema al abrir (ver `LaunchScreen.storyboard`), así no hay un salto.
class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(size: DesignTokens.logoSize),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(
          AppConfig.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}
