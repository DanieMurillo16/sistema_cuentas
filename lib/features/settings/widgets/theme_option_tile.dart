import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/settings/utils/theme_options.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';

/// Una opción de la pantalla «Tema»: icono, nombre y qué hace. La elegida lleva
/// borde de acento y un visto.
class ThemeOptionTile extends StatelessWidget {
  const ThemeOptionTile({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: '${mode.label}. ${mode.description}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(
            color: selected ? accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            child: Row(
              children: [
                CatalogBadge(icon: mode.icon, color: accent),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mode.label, style: textTheme.titleSmall),
                      Text(mode.description, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
