import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/widgets/app_shell_compact.dart';
import 'package:sistema_cuentas/shared/widgets/app_shell_wide.dart';

/// Esqueleto de la app una vez dentro: cabecera, menú y contenido.
///
/// - Ancho (>= `wideLayoutWidth`): menú lateral ([AppShellWide]).
/// - Angosto: píldora flotante sobre el contenido ([AppShellCompact]). Las
///   listas dejan `listBottomSpace` al final para no quedar tapadas.
///
/// El contenido es el mismo [child] en los dos casos, así que cambiar de
/// tamaño no pierde lo que se estuviera haciendo.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.destinations,
    required this.currentPath,
    required this.onSelected,
    required this.header,
    required this.child,
  });

  final List<AppDestination> destinations;
  final String currentPath;
  final ValueChanged<AppDestination> onSelected;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selected = destinations.indexWhere((d) => d.path == currentPath);
    final index = selected < 0 ? 0 : selected;
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: DesignTokens.contentMaxWidth,
        ),
        child: Column(
          children: [
            header,
            Expanded(child: child),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < DesignTokens.wideLayoutWidth) {
          return AppShellCompact(
            destinations: destinations,
            selectedIndex: index,
            onSelected: onSelected,
            content: content,
          );
        }
        return AppShellWide(
          destinations: destinations,
          selectedIndex: index,
          onSelected: onSelected,
          extended: width >= DesignTokens.expandedLayoutWidth,
          content: content,
        );
      },
    );
  }
}
