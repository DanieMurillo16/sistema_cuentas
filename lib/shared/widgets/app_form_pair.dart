import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Dos campos en fila cuando caben sin sacrificar legibilidad.
class AppFormPair extends StatelessWidget {
  const AppFormPair({
    super.key,
    required this.first,
    required this.second,
    this.minWidth = DesignTokens.formPairMinWidth,
    this.equalHeight = false,
  });

  final Widget first;
  final Widget second;
  final double minWidth;

  /// En fila, las dos miden lo mismo (la más alta manda). Para tarjetas que
  /// abren un selector: sus nombres pueden ocupar distinto número de líneas. Los
  /// campos de texto no lo necesitan.
  final bool equalHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inline =
          constraints.maxWidth >=
          MediaQuery.textScalerOf(context).scale(minWidth);
      final fieldWidth = inline
          ? (constraints.maxWidth - DesignTokens.spaceMd) / 2
          : constraints.maxWidth;
      if (equalHeight) {
        return inline
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: first),
                    const SizedBox(width: DesignTokens.spaceMd),
                    Expanded(child: second),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  first,
                  const SizedBox(height: DesignTokens.spaceMd),
                  second,
                ],
              );
      }
      return Wrap(
        spacing: DesignTokens.spaceMd,
        runSpacing: DesignTokens.spaceMd,
        children: [
          SizedBox(width: fieldWidth, child: first),
          SizedBox(width: fieldWidth, child: second),
        ],
      );
    },
  );
}
