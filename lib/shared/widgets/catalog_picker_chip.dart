import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

/// Una opción «frecuente» del selector: icono y nombre en una pastilla.
class CatalogPickerChip extends StatelessWidget {
  const CatalogPickerChip({
    super.key,
    required this.option,
    required this.onTap,
  });

  final CatalogPickerOption<Object> option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogBadge(
                icon: option.icon,
                color: option.color,
                size: DesignTokens.pickerChipBadgeSize,
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              Flexible(
                child: Text(
                  formatDisplayText(option.label),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceXs),
            ],
          ),
        ),
      ),
    );
  }
}
