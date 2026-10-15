import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Un monto ya formateado: verde si entra, rojo si sale; tapado con el ojo.
class MovementAmountText extends StatelessWidget {
  const MovementAmountText({
    super.key,
    required this.text,
    required this.income,
    required this.hidden,
    this.style,
    this.flexible = true,
  });

  final String text;
  final bool income;
  final bool hidden;
  final TextStyle? style;

  /// En `false` el monto no es hijo flexible de una fila: quien lo usa le pone
  /// su propio tope de ancho (así el texto de al lado se queda con lo demás).
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleSmall;
    // Flexible + FittedBox: con importes largos o texto grande el monto se
    // encoge antes de quitarle el ancho a la descripción.
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        hidden ? AnimatedNumberText.mask : text,
        maxLines: 1,
        softWrap: false,
        style: base?.copyWith(
          color: income ? AppColors.income : AppColors.expense,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return flexible ? Flexible(child: amount) : amount;
  }
}
