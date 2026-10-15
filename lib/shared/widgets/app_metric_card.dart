import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/app_metric_value.dart';
import 'package:sistema_cuentas/shared/widgets/visibility_toggle_button.dart';

/// Un indicador: título, cifra, icono y color de acento. Con [amount] la cifra
/// se anima; con [text] se muestra tal cual (ya formateada, nunca aquí). Con
/// [onToggleHidden] aparece el ojo para tapar la cifra.
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.amount,
    this.text,
    this.formatter = formatCop,
    this.hidden = false,
    this.onToggleHidden,
    this.showIcon = true,
  });

  final String title;
  final IconData icon;
  final Color color;
  final double? amount;
  final String? text;
  final String Function(num) formatter;
  final bool hidden;
  final VoidCallback? onToggleHidden;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Row(
          children: [
            if (showIcon) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  child: Icon(icon, color: color),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                  AppMetricValue(
                    amount: amount,
                    text: text,
                    formatter: formatter,
                    hidden: hidden,
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (onToggleHidden != null)
              VisibilityToggleButton(
                hidden: hidden,
                onTap: onToggleHidden!,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }
}
