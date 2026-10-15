import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// El texto del centro de la dona: la cifra y debajo su etiqueta (el total o la
/// categoría tocada). La cifra se encoge antes de partirse.
class DonutCenter extends StatelessWidget {
  const DonutCenter({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.donutCenterPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: textTheme.titleLarge),
          ),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
