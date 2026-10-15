import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_chip.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_row.dart';

/// El cuerpo desplazable del selector: «Frecuentes» (solo sin búsqueda) y
/// «Todas» (o «Resultados» al buscar). Si no hay coincidencias, lo dice.
class CatalogPickerList extends StatelessWidget {
  const CatalogPickerList({
    super.key,
    required this.options,
    required this.frequent,
    required this.selected,
    required this.searching,
    required this.onSelected,
  });

  final List<CatalogPickerOption<Object>> options;
  final List<CatalogPickerOption<Object>> frequent;
  final Object? selected;
  final bool searching;
  final ValueChanged<Object> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showFrequent = !searching && frequent.isNotEmpty;
    return CustomScrollView(
      // La hoja mide lo que midan sus opciones (hasta su máximo).
      shrinkWrap: true,
      slivers: [
        if (showFrequent) ...[
          _Title('FRECUENTES', style: textTheme.labelSmall),
          SliverToBoxAdapter(
            child: Wrap(
              spacing: DesignTokens.spaceSm,
              runSpacing: DesignTokens.spaceSm,
              children: [
                for (final option in frequent)
                  CatalogPickerChip(
                    key: ValueKey('frequent-${option.label}'),
                    option: option,
                    onTap: () => onSelected(option.value),
                  ),
              ],
            ),
          ),
        ],
        _Title(searching ? 'RESULTADOS' : 'TODAS', style: textTheme.labelSmall),
        if (options.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              child: Text('Sin resultados', style: textTheme.bodyMedium),
            ),
          )
        else
          SliverList.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return CatalogPickerRow(
                key: ValueKey('option-${option.label}'),
                option: option,
                selected: option.value == selected,
                onTap: () => onSelected(option.value),
              );
            },
          ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(
        top: DesignTokens.spaceMd,
        bottom: DesignTokens.spaceSm,
      ),
      child: Text(text, style: style),
    ),
  );
}
