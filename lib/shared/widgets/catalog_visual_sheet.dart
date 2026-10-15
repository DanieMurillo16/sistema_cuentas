import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/catalog_visuals.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_body.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_choice.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_header.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_visual_layout.dart';

/// Abre el selector de icono y color. Devuelve lo elegido al «Aplicar» (o un
/// [CatalogVisualChoice] vacío con «Quitar») y `null` si se cierra sin elegir.
Future<CatalogVisualChoice?> showCatalogVisualSheet(
  BuildContext context, {
  required CatalogVisualChoice initial,
  required IconData fallbackIcon,
  String? subject,
}) {
  return showModalBottomSheet<CatalogVisualChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // En pantalla ancha la hoja no se estira de lado a lado.
    constraints: const BoxConstraints(maxWidth: DesignTokens.dialogMaxWidth),
    // Por encima de la píldora del menú y del diálogo que lo abrió.
    useRootNavigator: true,
    builder: (_) => CatalogVisualSheet(
      initial: initial,
      fallbackIcon: fallbackIcon,
      subject: subject,
    ),
  );
}

enum _Tab { icon, color }

class CatalogVisualSheet extends StatefulWidget {
  const CatalogVisualSheet({
    super.key,
    required this.initial,
    required this.fallbackIcon,
    this.subject,
  });

  final CatalogVisualChoice initial;
  final IconData fallbackIcon;

  /// El nombre de la categoría o el contacto que se está cambiando.
  final String? subject;

  @override
  State<CatalogVisualSheet> createState() => _CatalogVisualSheetState();
}

class _CatalogVisualSheetState extends State<CatalogVisualSheet> {
  // Estado efímero y visual de la hoja: pestaña, búsqueda y lo elegido.
  late String? _icon = widget.initial.icon;
  late String? _color = widget.initial.color;
  var _tab = _Tab.icon;
  var _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Por debajo de este alto de hoja el título y la vista previa no caben.
  static const _compactHeight = 420.0;

  List<CatalogIcon> get _icons => [
    for (final icon in CatalogVisuals.icons)
      if (icon.matches(_query)) icon,
  ];

  /// Con el teclado abierto la hoja se encoge en vez de quedar tapada; el asa
  /// de arrastre del tema ocupa su propio alto.
  double _sheetHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final room = math.max(
      0.0,
      size.height -
          MediaQuery.viewInsetsOf(context).bottom -
          MediaQuery.paddingOf(context).top -
          kMinInteractiveDimension,
    );
    return math.min(size.height * DesignTokens.sheetMaxHeightFactor, room);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final color = CatalogVisuals.colorFor(_color, fallback: AppColors.accent);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: _sheetHeight(context),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd).copyWith(top: 0),
          child: CatalogVisualLayout(
            header: CatalogVisualHeader(
              icon: CatalogVisuals.iconFor(
                _icon,
                fallback: widget.fallbackIcon,
              ),
              color: color,
              subject: widget.subject,
              compact: keyboard > 0 || _sheetHeight(context) < _compactHeight,
              showIcons: _tab == _Tab.icon,
              onShowIcons: (value) {
                FocusScope.of(context).unfocus();
                setState(() => _tab = value ? _Tab.icon : _Tab.color);
              },
            ),
            body: CatalogVisualBody(
              showIcons: _tab == _Tab.icon,
              icons: _icons,
              selectedIcon: _icon,
              selectedColor: _color,
              tint: color,
              search: _search,
              onQuery: (value) => setState(() => _query = value),
              onIcon: (key) => setState(() => _icon = key),
              onColor: (hex) => setState(() => _color = hex),
            ),
            actions: _Actions(
              onClear: () =>
                  Navigator.of(context).pop(const CatalogVisualChoice()),
              onApply: () =>
                  Navigator.of(context)
                      .pop(CatalogVisualChoice(icon: _icon, color: _color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onClear, required this.onApply});

  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClear,
            child: const Text('Quitar'),
          ),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: FilledButton(onPressed: onApply, child: const Text('Aplicar')),
        ),
      ],
    );
  }
}
