import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_method_lines.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_methods_toggle.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/shared/widgets/app_collapse.dart';

/// «Detalle ⌄» y, debajo, el desglose por medio de pago cuando está abierto.
class BalanceMethodsSection extends StatelessWidget {
  const BalanceMethodsSection({
    super.key,
    required this.type,
    required this.methods,
    required this.hidden,
    required this.expanded,
    required this.onToggle,
  });

  final MovementType type;
  final List<MethodTotal> methods;
  final bool hidden;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        0,
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BalanceMethodsToggle(type: type, expanded: expanded, onTap: onToggle),
          AppCollapse(
            visible: expanded,
            child: BalanceMethodLines(methods: methods, hidden: hidden),
          ),
        ],
      ),
    );
  }
}
