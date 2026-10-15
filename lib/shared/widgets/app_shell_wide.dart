import 'package:flutter/material.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';

/// Distribución ancha del shell: menú lateral (plegado a iconos hasta
/// `expandedLayoutWidth`, extendido desde ahí) y el contenido al lado.
class AppShellWide extends StatelessWidget {
  const AppShellWide({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.extended,
    required this.content,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<AppDestination> onSelected;
  final bool extended;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              labelType: extended ? null : NavigationRailLabelType.selected,
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => onSelected(destinations[i]),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
