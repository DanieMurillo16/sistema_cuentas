import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/label_amount_row.dart';

/// «Etiqueta … monto»: el monto se encoge antes de partirse y se tapa con el ojo.
class SummaryAmountRow extends StatelessWidget {
  const SummaryAmountRow({
    super.key,
    required this.label,
    required this.amount,
    required this.hidden,
    this.color,
    this.emphasized = false,
  });

  final String label;
  final String amount;
  final bool hidden;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = (emphasized ? textTheme.headlineSmall : textTheme.bodyLarge)
        ?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
      child: LabelAmountRow(
        label: Text(label, style: textTheme.bodyMedium),
        amount: Semantics(
          label: hidden ? 'Monto oculto' : amount,
          excludeSemantics: true,
          child: Text(
            hidden ? AnimatedNumberText.mask : amount,
            maxLines: 1,
            softWrap: false,
            style: style,
          ),
        ),
      ),
    );
  }
}
