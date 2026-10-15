import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// La cifra de un indicador: con [amount] cuenta/se desliza y puede taparse;
/// con [text] (ya formateado) muestra el texto tal cual.
class AppMetricValue extends StatelessWidget {
  const AppMetricValue({
    super.key,
    this.amount,
    this.text,
    this.formatter = formatCop,
    this.hidden = false,
    this.style,
  }) : assert(amount != null || text != null, 'Pasa amount o text');

  final double? amount;
  final String? text;
  final String Function(num) formatter;
  final bool hidden;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (amount != null) {
      return AnimatedNumberText(
        value: amount!,
        obscured: hidden,
        formatter: formatter,
        style: style,
      );
    }
    return Text(
      hidden ? AnimatedNumberText.mask : text!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
