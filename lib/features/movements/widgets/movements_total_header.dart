import 'package:flutter/material.dart';
import 'package:sistema_cuentas/shared/widgets/label_amount_row.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';

/// Cuántos movimientos hay con los filtros puestos y cuánto suman.
class MovementsTotalHeader extends StatelessWidget {
  const MovementsTotalHeader({
    super.key,
    required this.type,
    required this.count,
    required this.totalCents,
    required this.hidden,
  });

  final MovementType type;
  final int count;
  final int totalCents;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceMd,
        0,
        DesignTokens.spaceMd,
        DesignTokens.spaceSm,
      ),
      child: LabelAmountRow(
        label: Text(
          '$count ${count == 1 ? 'movimiento' : 'movimientos'}',
          style: textTheme.bodyMedium,
        ),
        amount: AnimatedNumberText(
          value: centsToPesos(totalCents),
          obscured: hidden,
          style: textTheme.titleMedium?.copyWith(color: type.color),
        ),
      ),
    );
  }
}
