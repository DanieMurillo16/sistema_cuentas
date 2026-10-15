import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_form_rules.dart';

/// La fecha en una píldora: «martes, 13 de octubre de 2026». Al tocarla abre el
/// calendario; no se puede elegir una fecha futura.
class DatePill extends StatelessWidget {
  const DatePill({
    super.key,
    required this.date,
    required this.onChanged,
    required this.enabled,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final last = MovementFormRules.lastDate(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: date.isAfter(last) ? last : date,
      firstDate: MovementFormRules.firstDate,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Fecha: ${formatLongDate(date)}. Toca para cambiarla',
        excludeSemantics: true,
        child: Material(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            onTap: enabled ? () => _pick(context) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: DesignTokens.controlMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceMd,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: DesignTokens.iconMd,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Flexible(
                      child: Text(
                        formatLongDate(date),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
