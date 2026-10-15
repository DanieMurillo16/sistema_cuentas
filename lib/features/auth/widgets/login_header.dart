import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/config/app_config.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/brand_logo.dart';

/// Logo, nombre de la app e indicación de la pantalla de login.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(size: DesignTokens.logoSize),
        const SizedBox(height: DesignTokens.spaceLg),
        Text(
          AppConfig.appName,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          'Inicia sesión para ver tus cuentas',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
