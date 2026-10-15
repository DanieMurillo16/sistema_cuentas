import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Una línea «etiqueta … valor» de una ficha. El valor pasa a la línea de abajo
/// si no cabe (nombres largos, texto grande): nunca desborda.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: DesignTokens.spaceMd,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
