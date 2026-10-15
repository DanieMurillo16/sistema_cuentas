import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Tarjeta de espera: barra que corre y qué se está cargando. La usa
/// `AppLoadingVeil` para cargas que cambian la pantalla entera.
class AppLoadingCard extends StatelessWidget {
  const AppLoadingCard({super.key, required this.message});

  final String message;

  static const double _barWidth = 220;
  static const double _barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXl,
          vertical: DesignTokens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _barWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_barHeight),
                child: const LinearProgressIndicator(minHeight: _barHeight),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
