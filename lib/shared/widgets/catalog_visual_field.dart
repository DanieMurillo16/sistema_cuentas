import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_badge.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_choice.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_sheet.dart';

/// Campo «Icono y color» de un formulario: muestra cómo se ve y, al tocarlo,
/// abre el selector. Devuelve lo elegido por [onChanged].
class CatalogVisualField extends StatelessWidget {
  const CatalogVisualField({
    super.key,
    required this.choice,
    required this.fallbackIcon,
    required this.onChanged,
    this.subject,
    this.enabled = true,
  });

  final CatalogVisualChoice choice;

  /// El icono que se ve mientras no se elija ninguno.
  final IconData fallbackIcon;
  final ValueChanged<CatalogVisualChoice> onChanged;

  /// El nombre de lo que se está cambiando, leído al abrir el selector (el
  /// usuario puede haberlo escrito hace un momento).
  final ValueGetter<String>? subject;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    final picked = await showCatalogVisualSheet(
      context,
      initial: choice,
      fallbackIcon: fallbackIcon,
      subject: subject?.call().trim(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chosen = choice.icon != null || choice.color != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Icono y color',
      value: chosen ? 'Elegido' : 'Sin elegir',
      hint: 'Abre el selector de icono y color',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: enabled ? () => _open(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
          child: Row(
            children: [
              CatalogBadge(
                icon: CatalogVisuals.iconFor(
                  choice.icon,
                  fallback: fallbackIcon,
                ),
                color: CatalogVisuals.colorFor(
                  choice.color,
                  fallback: AppColors.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Icono y color', style: textTheme.titleSmall),
                    Text(
                      chosen ? 'Toca para cambiarlos' : 'Toca para elegirlos',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
