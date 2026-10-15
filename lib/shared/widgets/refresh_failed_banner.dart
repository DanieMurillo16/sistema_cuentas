import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Aviso en la parte de arriba cuando un refresco falló pero hay datos en
/// pantalla: los datos se conservan y se ofrece reintentar.
class RefreshFailedBanner extends StatelessWidget {
  const RefreshFailedBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: DesignTokens.iconMd,
              color: AppColors.expense,
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
