import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/utils/search_options.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_footer.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_header.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_list.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_picker_option.dart';

/// Abre el selector de categoría o medio de pago (hoja inferior con buscador,
/// frecuentes y todas) y devuelve lo elegido, o `null` si se cierra. El teclado
/// se cierra antes: el selector no lo necesita hasta que se toque la búsqueda.
///
/// [searchable] en `false` esconde el buscador (pocas opciones).
///
/// [onCreate] (opcional) abre el alta de uno nuevo y devuelve el creado; si lo
/// hay, queda elegido y la hoja se cierra.
Future<T?> showCatalogPicker<T extends Object>(
  BuildContext context, {
  required String title,
  required String createLabel,
  required List<CatalogPickerOption<T>> options,
  List<CatalogPickerOption<T>> frequent = const [],
  T? selected,
  Future<T?> Function()? onCreate,
  bool searchable = true,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => CatalogPickerSheet<T>(
      title: title,
      createLabel: createLabel,
      options: options,
      frequent: frequent,
      selected: selected,
      onCreate: onCreate,
      searchable: searchable,
    ),
  );
}

class CatalogPickerSheet<T extends Object> extends StatefulWidget {
  const CatalogPickerSheet({
    super.key,
    required this.title,
    required this.createLabel,
    required this.options,
    required this.frequent,
    required this.selected,
    required this.onCreate,
    this.searchable = true,
  });

  final String title;
  final String createLabel;
  final List<CatalogPickerOption<T>> options;
  final List<CatalogPickerOption<T>> frequent;
  final T? selected;
  final Future<T?> Function()? onCreate;
  final bool searchable;

  @override
  State<CatalogPickerSheet<T>> createState() => _CatalogPickerSheetState<T>();
}

class _CatalogPickerSheetState<T extends Object>
    extends State<CatalogPickerSheet<T>> {
  // Estado efímero y visual: lo que se escribe en el buscador.
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await widget.onCreate!();
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mide lo que midan sus opciones, hasta el máximo; y con el teclado, lo
        // que deja libre (el menor de los dos: continuo, sin saltos).
        final inset = MediaQuery.viewInsetsOf(context).bottom;
        final maxHeight = math.min(
          constraints.maxHeight * DesignTokens.sheetMaxHeightFactor,
          constraints.maxHeight - inset,
        );
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceMd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CatalogPickerHeader(
                    title: widget.title,
                    controller: _query,
                    searchable: widget.searchable,
                    onChanged: (_) => setState(() {}),
                  ),
                  Flexible(
                    child: CatalogPickerList(
                      options: searchOptions<CatalogPickerOption<T>>(
                        widget.options,
                        (option) => option.label,
                        _query.text,
                      ).toList(),
                      frequent: widget.frequent,
                      selected: widget.selected,
                      searching: _query.text.trim().isNotEmpty,
                      onSelected: (value) =>
                          Navigator.of(context).pop(value as T),
                    ),
                  ),
                  CatalogPickerFooter(
                    createLabel: widget.createLabel,
                    onCreate: widget.onCreate == null ? null : _create,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
