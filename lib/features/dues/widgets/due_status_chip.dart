import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';

/// El estado de un vencimiento en una etiqueta: color por tono (vencido en
/// rojo, hoy en ámbar, pagado en verde) y siempre con texto.
class DueStatusChip extends StatelessWidget {
  const DueStatusChip({super.key, required this.info});

  final DueStatusInfo info;

  Color get _color => switch (info.tone) {
    DueTone.danger => AppColors.expense,
    DueTone.warning => AppColors.warningText,
    DueTone.success => AppColors.income,
    DueTone.neutral => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceSm + DesignTokens.spaceXs,
          vertical: DesignTokens.spaceXs,
        ),
        child: Text(
          info.label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: _color),
        ),
      ),
    );
  }
}
