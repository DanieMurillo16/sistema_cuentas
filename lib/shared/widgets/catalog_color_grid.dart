import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';

/// Los colores de la paleta, como círculos. El elegido lleva un visto.
class CatalogColorGrid extends StatelessWidget {
  const CatalogColorGrid({
    super.key,
    required this.selectedHex,
    required this.onSelected,
  });

  final String? selectedHex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: DesignTokens.spaceSm,
        runSpacing: DesignTokens.spaceSm,
        children: [
          for (final (index, hex) in CatalogVisuals.palette.indexed)
            _Swatch(
              hex: hex,
              position: index + 1,
              selected: hex.toUpperCase() == selectedHex?.toUpperCase(),
              onTap: () => onSelected(hex),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.position,
    required this.selected,
    required this.onTap,
  });

  final String hex;

  /// Lugar en la paleta (1 a 30): el lector dice «Color 3 de 12», no el código.
  final int position;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Color $position de ${CatalogVisuals.palette.length}',
      excludeSemantics: true,
      // El círculo mide 40 pero el toque llega a 48.
      child: InkWell(
        key: ValueKey('catalog-color-$hex'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: kMinInteractiveDimension,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CatalogVisuals.colorFor(hex, fallback: AppColors.muted),
              ),
              child: SizedBox.square(
                dimension: DesignTokens.colorSwatchSize,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: _checkColor(
                          CatalogVisuals.colorFor(
                            hex,
                            fallback: AppColors.muted,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El visto, del color (oscuro o claro) que más contraste dé sobre [swatch].
Color _checkColor(Color swatch) {
  double contrast(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  return contrast(swatch, AppColors.brand) >=
          contrast(swatch, AppColors.onBrand)
      ? AppColors.brand
      : AppColors.onBrand;
}
