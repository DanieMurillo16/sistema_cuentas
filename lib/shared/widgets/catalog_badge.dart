import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Cuadro redondeado con el icono elegido para una categoría o un contacto,
/// sobre un fondo tenue del mismo color.
class CatalogBadge extends StatelessWidget {
  const CatalogBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = DesignTokens.avatarSize,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: DesignTokens.tintFill),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          icon,
          color: color,
          size: size * DesignTokens.visualBadgeRatio,
        ),
      ),
    );
  }
}
