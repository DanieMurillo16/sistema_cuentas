import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_header.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// La parte que se toca de una tarjeta del balance: «Ingresos» o «Gastos» y su
/// total. Abre la lista de ese tipo. Es lo único que lee el lector de pantalla
/// como una sola cosa; el despegable por medio va aparte, con su propia acción.
class BalanceStatMain extends StatelessWidget {
  const BalanceStatMain({
    super.key,
    required this.type,
    required this.cents,
    required this.hidden,
    required this.padding,
    this.onTap,
  });

  final MovementType type;

  /// El total del tipo (siempre positivo): el signo lo pone el tipo.
  final int cents;
  final bool hidden;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final signed = type.isIncome ? cents : -cents;
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      label: hidden
          ? '${type.plural}, monto oculto'
          : '${type.plural}, ${formatCentsSigned(signed)}',
      hint: onTap == null
          ? null
          : 'Abre la lista de ${type.plural.toLowerCase()}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalanceStatHeader(type: type, tappable: onTap != null),
              const SizedBox(height: DesignTokens.spaceSm),
              AnimatedNumberText(
                value: centsToPesos(signed),
                obscured: hidden,
                formatter: formatCopSigned,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.onBrand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
