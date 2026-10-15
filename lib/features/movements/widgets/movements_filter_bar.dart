import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movements_filter_panel.dart';
import 'package:sistema_cuentas/shared/widgets/app_collapse.dart';

/// Buscador y, plegables, los filtros (fechas, categoría, medio). El texto
/// filtra lo ya cargado; lo demás vuelve a pedirse al servidor.
class MovementsFilterBar extends ConsumerStatefulWidget {
  const MovementsFilterBar({super.key, required this.type});

  final MovementType type;

  @override
  ConsumerState<MovementsFilterBar> createState() => _MovementsFilterBarState();
}

class _MovementsFilterBarState extends ConsumerState<MovementsFilterBar> {
  // Estado efímero y visual: el campo y si el panel está abierto.
  late final _controller = TextEditingController(
    text: ref.read(movementsFilterProvider(widget.type)).query,
  );
  var _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) =>
      ref.read(movementsFilterProvider(widget.type).notifier).setQuery(value);

  @override
  Widget build(BuildContext context) {
    final extras = ref.watch(
      movementsFilterProvider(widget.type).select((f) => f.hasExtras),
    );
    // Si el filtro se limpia desde el panel, el campo también se vacía.
    ref.listen(movementsFilterProvider(widget.type).select((f) => f.query), (
      _,
      query,
    ) {
      if (_controller.text != query) _controller.text = query;
    });
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            onChanged: _setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por descripción, categoría o medio',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: _open ? 'Ocultar filtros' : 'Filtros',
                onPressed: () => setState(() => _open = !_open),
                icon: Icon(
                  extras ? Icons.filter_alt_rounded : Icons.tune_rounded,
                ),
              ),
            ),
          ),
          AppCollapse(
            visible: _open,
            child: Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
              child: MovementsFilterPanel(type: widget.type),
            ),
          ),
        ],
      ),
    );
  }
}
