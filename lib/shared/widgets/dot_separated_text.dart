import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Varios datos en una línea separados por « · » («Suscripciones · 24 oct.»).
/// Cada dato es indivisible: si no caben todos, el que no cabe pasa completo a
/// la línea de abajo (una fecha nunca queda partida en dos).
class DotSeparatedText extends StatelessWidget {
  const DotSeparatedText({super.key, required this.parts, this.style});

  final List<String> parts;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? Theme.of(context).textTheme.bodySmall;
    return Semantics(
      // El lector dice los datos seguidos, no cada «·» por separado.
      label: parts.join(', '),
      excludeSemantics: true,
      child: Wrap(
        spacing: DesignTokens.spaceXs,
        children: [
          for (final (index, part) in parts.indexed)
            Text(index < parts.length - 1 ? '$part ·' : part, style: textStyle),
        ],
      ),
    );
  }
}
