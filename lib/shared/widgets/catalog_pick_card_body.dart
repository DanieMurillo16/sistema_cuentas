import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

/// El interior de [CatalogPickCard]: arriba la etiqueta y la flecha; abajo, lo
/// elegido (icono y nombre, que crece) o «Elegir» si aún no hay nada.
class CatalogPickCardBody extends StatelessWidget {
  const CatalogPickCardBody({
    super.key,
    required this.label,
    required this.placeholderIcon,
    required this.selected,
    required this.errorText,
    required this.onTap,
    this.placeholder = 'Elegir',
    this.onClear,
  });

  final String label;
  final IconData placeholderIcon;
  final CatalogPickerOption<Object>? selected;

  /// Si no es `null`, el borde se pone rojo y el texto va dentro de la tarjeta.
  final String? errorText;
  final VoidCallback onTap;

  /// Lo que se lee mientras no hay nada elegido («Elegir», «Todas»…).
  final String placeholder;

  /// Si no es `null` y hay algo elegido, aparece una «x» para quitarlo (campos
  /// opcionales y filtros).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      side: BorderSide(
        color: errorText != null ? AppColors.expense : AppColors.inputBorder,
      ),
    );
    return Material(
      color: AppColors.surface,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.pickCardMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, style: textTheme.bodySmall)),
                    if (onClear != null && selected != null)
                      SizedBox(
                        width: DesignTokens.pickClearWidth,
                        height: DesignTokens.pickClearHeight,
                        child: IconButton(
                          tooltip: 'Quitar',
                          padding: EdgeInsets.zero,
                          iconSize: DesignTokens.iconMd,
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      )
                    else
                      Icon(Icons.expand_more_rounded, color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                _Value(
                  selected: selected,
                  placeholderIcon: placeholderIcon,
                  placeholder: placeholder,
                  textTheme: textTheme,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    errorText!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.selected,
    required this.placeholderIcon,
    required this.placeholder,
    required this.textTheme,
  });

  final CatalogPickerOption<Object>? selected;
  final IconData placeholderIcon;
  final String placeholder;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final option = selected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (option == null)
          Icon(placeholderIcon, color: AppColors.muted)
        else
          CatalogBadge(
            icon: option.icon,
            color: option.color,
            size: DesignTokens.pickerSmallBadgeSize,
          ),
        const SizedBox(width: DesignTokens.spaceSm),
        Expanded(
          child: Text(
            option == null ? placeholder : formatDisplayText(option.label),
            style: option == null
                ? textTheme.bodyLarge?.copyWith(color: AppColors.muted)
                : textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}
