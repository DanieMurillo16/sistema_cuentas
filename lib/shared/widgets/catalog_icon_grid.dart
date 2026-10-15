import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';

/// Rejilla de iconos para elegir (se arma por demanda). El elegido se resalta
/// con el [color] actual; cada celda tiene su nombre para el lector de pantalla.
class CatalogIconGrid extends StatelessWidget {
  const CatalogIconGrid({
    super.key,
    required this.icons,
    required this.selectedKey,
    required this.color,
    required this.onSelected,
  });

  final List<CatalogIcon> icons;
  final String? selectedKey;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: DesignTokens.iconCellMaxExtent,
        mainAxisSpacing: DesignTokens.spaceSm,
        crossAxisSpacing: DesignTokens.spaceSm,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final option = icons[index];
        final selected = option.key == selectedKey;
        return Semantics(
          button: true,
          selected: selected,
          label: option.label,
          excludeSemantics: true,
          child: Tooltip(
            message: option.label,
            child: Material(
              color: selected
                  ? color.withValues(alpha: DesignTokens.tintFill)
                  : AppColors.surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(
                  color: selected ? color : AppColors.transparent,
                ),
              ),
              child: InkWell(
                key: ValueKey('catalog-icon-${option.key}'),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                onTap: () => onSelected(option.key),
                child: Icon(
                  option.icon,
                  color: selected ? color : AppColors.muted,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
