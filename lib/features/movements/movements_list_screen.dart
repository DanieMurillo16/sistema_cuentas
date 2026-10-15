import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/models/movements_filter.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movements_filter_bar.dart';
import 'package:sistema_cuentas/features/movements/widgets/movements_list_body.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_sub_screen_bar.dart';

/// Todos los ingresos (o todos los gastos) con buscador y filtros por fechas,
/// categoría y medio de pago. Se llega tocando la tarjeta de Ingresos o de
/// Gastos del balance de Inicio.
/// pantalla → filteredMovementsProvider → MovementsRepository → movimientos/listar.php
class MovementsListScreen extends ConsumerWidget {
  const MovementsListScreen({super.key, required this.type});

  final MovementType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(movementsFilterProvider(type));
    return Scaffold(
      appBar: AppSubScreenBar(title: type.plural, fallbackPath: AppRoutes.home),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.formMaxWidth,
            ),
            // Los filtros miden lo que midan hasta la mitad del alto (y se
            // desplazan si no caben, p. ej. con el teclado abierto); la lista
            // se queda con el resto.
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.5,
                    ),
                    child: SingleChildScrollView(
                      child: MovementsFilterBar(type: type),
                    ),
                  ),
                  Expanded(
                    child: AppAsyncView(
                      state: ref.watch(filteredMovementsProvider(type)),
                      isEmpty: (items) => items.isEmpty,
                      emptyIcon: Icons.search_off_rounded,
                      emptyTitle: 'Sin resultados',
                      emptyMessage: _emptyMessage(filter),
                      onRetry: () =>
                          ref.invalidate(movementsListProvider(type)),
                      builder: (items) => MovementsListBody(type: type),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _emptyMessage(MovementsFilter filter) => filter.hasExtras
      ? 'Ningún movimiento coincide con tu búsqueda y tus filtros.'
      : 'No hay ${type.plural.toLowerCase()} en estas fechas.';
}
