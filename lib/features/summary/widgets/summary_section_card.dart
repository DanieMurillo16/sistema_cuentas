import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Una sección del resumen: título, una línea de apoyo opcional y su contenido.
class SummarySectionCard extends StatelessWidget {
  const SummarySectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            if (subtitle != null) Text(subtitle!, style: textTheme.bodySmall),
            const SizedBox(height: DesignTokens.spaceMd),
            child,
          ],
        ),
      ),
    );
  }
}
