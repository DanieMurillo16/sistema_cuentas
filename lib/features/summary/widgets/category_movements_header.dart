import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';

/// Título de la hoja de una categoría: su nombre y cuántos movimientos tuvo en
/// el mes.
class CategoryMovementsHeader extends StatelessWidget {
  const CategoryMovementsHeader({
    super.key,
    required this.name,
    required this.count,
    required this.month,
  });

  final String name;
  final int count;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatDisplayText(name), style: textTheme.titleLarge),
          Text(
            '$count ${count == 1 ? 'movimiento' : 'movimientos'} en ${formatMonthLong(month)}',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
