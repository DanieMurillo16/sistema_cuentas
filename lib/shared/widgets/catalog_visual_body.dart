import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_color_grid.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_icon_grid.dart';

/// El cuerpo de la hoja: en «Icono», buscador y rejilla; en «Color», la paleta.
class CatalogVisualBody extends StatelessWidget {
  const CatalogVisualBody({
    super.key,
    required this.showIcons,
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.tint,
    required this.search,
    required this.onQuery,
    required this.onIcon,
    required this.onColor,
  });

  final bool showIcons;
  final List<CatalogIcon> icons;
  final String? selectedIcon;
  final String? selectedColor;
  final Color tint;

  /// El texto del buscador vive en la hoja: al pasar a «Color» y volver, el
  /// campo y la lista siguen diciendo lo mismo.
  final TextEditingController search;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onIcon;
  final ValueChanged<String> onColor;

  @override
  Widget build(BuildContext context) {
    if (!showIcons) {
      return CatalogColorGrid(selectedHex: selectedColor, onSelected: onColor);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Con muy poco alto (teclado abierto y texto grande) el buscador no
        // cabe junto a la rejilla: se queda la rejilla.
        final showSearch =
            constraints.maxHeight >=
            MediaQuery.textScalerOf(context).scale(DesignTokens.searchMinRoom);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSearch) ...[
              TextField(
                controller: search,
                onChanged: onQuery,
                decoration: const InputDecoration(
                  hintText: 'Buscar icono…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
            ],
            Expanded(
              child: _IconsOrEmpty(
                icons: icons,
                selectedKey: selectedIcon,
                color: tint,
                onSelected: onIcon,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IconsOrEmpty extends StatelessWidget {
  const _IconsOrEmpty({
    required this.icons,
    required this.selectedKey,
    required this.color,
    required this.onSelected,
  });

  final List<CatalogIcon> icons;
  final String? selectedKey;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (icons.isEmpty) {
      return const Center(child: Text('No hay un icono con ese nombre.'));
    }
    return CatalogIconGrid(
      icons: icons,
      selectedKey: selectedKey,
      color: color,
      onSelected: onSelected,
    );
  }
}
