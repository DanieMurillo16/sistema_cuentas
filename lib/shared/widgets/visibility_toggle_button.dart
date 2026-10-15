import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';

/// El ojo que tapa o destapa una cifra (saldos, totales). El icono cambia con
/// un fundido, no a golpe. Con [compact] no pide el área de 48 px de Material
/// (en una tarjeta a media pantalla de teléfono esos píxeles salen del título).
class VisibilityToggleButton extends StatelessWidget {
  const VisibilityToggleButton({
    super.key,
    required this.hidden,
    required this.onTap,
    this.compact = false,
    this.color,
  });

  final bool hidden;
  final VoidCallback onTap;
  final bool compact;

  /// Color del icono; sin él, el del texto secundario del tema.
  final Color? color;

  static const double _compactSide = DesignTokens.compactTapTarget;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      tooltip: hidden ? 'Mostrar cifras' : 'Ocultar cifras',
      onPressed: onTap,
      padding: compact ? EdgeInsets.zero : null,
      visualDensity: compact ? VisualDensity.compact : null,
      constraints: compact
          ? const BoxConstraints.tightFor(
              width: _compactSide,
              height: _compactSide,
            )
          : null,
      icon: AnimatedSwitcher(
        duration: motionDuration(context, DesignTokens.animationFast),
        child: Icon(
          hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          key: ValueKey(hidden),
          color: iconColor,
          size: compact ? DesignTokens.iconSm : DesignTokens.iconMd,
        ),
      ),
    );
  }
}
