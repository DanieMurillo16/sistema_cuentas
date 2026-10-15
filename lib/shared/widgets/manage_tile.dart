import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';

/// Una fila de una lista que se administra (categoría, medio, contacto,
/// usuario): icono, nombre completo, detalle y «Inactivo» si está apagado.
class ManageTile extends StatelessWidget {
  const ManageTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.inactive = false,
    this.tint,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool inactive;

  /// Color del icono; sin él, el de acento. Inactiva siempre se ve apagada.
  final Color? tint;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = inactive ? AppColors.muted : tint ?? AppColors.accent;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Row(
            children: [
              CatalogBadge(icon: icon, color: color),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDisplayText(title),
                      style: textTheme.titleSmall?.copyWith(
                        color: inactive ? AppColors.muted : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: textTheme.bodySmall),
                    if (inactive)
                      Text('Inactivo', style: textTheme.labelMedium),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
