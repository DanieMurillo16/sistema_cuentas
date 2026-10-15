import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';

/// Título, vista previa y el conmutador Icono / Color.
class CatalogVisualHeader extends StatelessWidget {
  const CatalogVisualHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.subject,
    required this.compact,
    required this.showIcons,
    required this.onShowIcons,
  });

  final IconData icon;
  final Color color;
  final String? subject;

  /// Con el teclado abierto no cabe nada más que el conmutador.
  final bool compact;
  final bool showIcons;
  final ValueChanged<bool> onShowIcons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text('Icono y color', style: Theme.of(context).textTheme.titleLarge),
          if (subject != null && subject!.isNotEmpty)
            Text(
              formatDisplayText(subject!),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: AppColors.accent),
            ),
          const SizedBox(height: DesignTokens.spaceMd),
          Center(
            child: CatalogBadge(
              icon: icon,
              color: color,
              size: DesignTokens.visualPreviewSize,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
        ],
        AppToggle<bool>(
          selected: showIcons,
          onSelected: onShowIcons,
          options: const [
            AppToggleOption(value: true, label: 'Icono'),
            AppToggleOption(value: false, label: 'Color'),
          ],
        ),
      ],
    );
  }
}
