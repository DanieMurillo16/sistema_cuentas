import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/widgets/floating_pill_item.dart';

/// Barra inferior flotante en forma de píldora. Todas las pestañas miden lo
/// mismo y la elegida lleva un resaltado detrás; todas son solo icono (el nombre sale en tooltip y para
/// lectores de pantalla).
class FloatingPillNav extends StatelessWidget {
  const FloatingPillNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _inset = DesignTokens.spaceXs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navBar,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: AppColors.border),
        // En el tema claro la píldora blanca se fundiría con las tarjetas.
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: SizedBox(
          height: DesignTokens.floatingNavHeight,
          // Todas las pestañas miden lo mismo; solo la elegida se resalta.
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: FloatingPillItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
