import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: DesignTokens.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: DesignTokens.logoSize,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }
}
