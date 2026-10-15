import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_methods_section.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_main.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';

/// Tarjeta pequeña bajo el balance: Ingresos (verde, +) o Gastos (rojo, −).
/// Debajo del total, en pequeño, lo de cada medio de pago. Al tocarla se abre
/// la lista de ese tipo.
class BalanceStatTile extends StatelessWidget {
  const BalanceStatTile({
    super.key,
    required this.type,
    required this.cents,
    required this.hidden,
    this.methods = const [],
    this.methodsExpanded = false,
    this.onToggleMethods,
    this.onTap,
    this.anchorKey,
  });

  final MovementType type;

  /// El total del tipo (siempre positivo): el signo lo pone el tipo.
  final int cents;
  final bool hidden;

  /// Lo que dejó cada medio de pago en este tipo, de mayor a menor.
  final List<MethodTotal> methods;

  /// El desglose por medio empieza cerrado: se abre con «Detalle».
  final bool methodsExpanded;
  final VoidCallback? onToggleMethods;
  final VoidCallback? onTap;

  /// Para que la animación de «registrar» encuentre esta tarjeta en pantalla.
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final withMethods = methods.isNotEmpty && onToggleMethods != null;
    return DecoratedBox(
      key: anchorKey,
      decoration: BoxDecoration(
        color: type.fill.withValues(alpha: DesignTokens.tintFill),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: type.fill.withValues(alpha: DesignTokens.tintBorder),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BalanceStatMain(
              type: type,
              cents: cents,
              hidden: hidden,
              padding: const EdgeInsets.all(DesignTokens.spaceMd)
                  .copyWith(bottom: withMethods ? DesignTokens.spaceXs : null),
              onTap: onTap,
            ),
            if (withMethods)
              BalanceMethodsSection(
                type: type,
                methods: methods,
                hidden: hidden,
                expanded: methodsExpanded,
                onToggle: onToggleMethods!,
              ),
          ],
        ),
      ),
    );
  }
}
