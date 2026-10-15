import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

/// Una fila de la lista «Todas» del selector: icono, nombre y, si es la
/// elegida, una marca. El nombre crece, no se recorta.
class CatalogPickerRow extends StatelessWidget {
  const CatalogPickerRow({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CatalogPickerOption<Object> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      label: formatDisplayText(option.label),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceSm,
            vertical: DesignTokens.spaceSm,
          ),
          child: Row(
            children: [
              CatalogBadge(
                icon: option.icon,
                color: option.color,
                size: DesignTokens.pickerBadgeSize,
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Text(
                  formatDisplayText(option.label),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (selected) Icon(Icons.check_rounded, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
