import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';

/// Una pestaña de la píldora: solo icono; la elegida lleva un resaltado de
/// ancho fijo detrás. Enfocable con teclado y con feedback de toque.
class FloatingPillItem extends StatelessWidget {
  const FloatingPillItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(
              child: AnimatedContainer(
                duration: motionDuration(context, DesignTokens.animationNormal),
                curve: DesignTokens.curve,
                width: DesignTokens.pillHighlightWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.navHighlight
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected ? AppColors.accent : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
