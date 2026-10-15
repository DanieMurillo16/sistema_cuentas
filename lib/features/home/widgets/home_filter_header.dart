import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/home_type_toggle.dart';

/// El conmutador Todos / Ingresos / Gastos, fijo arriba al hacer scroll para
/// poder cambiar de vista sin volver al inicio de la lista.
class HomeFilterHeader extends StatelessWidget {
  const HomeFilterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // El alto fijo crece con el texto ampliado: si no, el conmutador se recortaría.
    final extent = MediaQuery.textScalerOf(context)
        .scale(DesignTokens.filterHeaderExtent);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterHeaderDelegate(extent, AppColors.background),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FilterHeaderDelegate(this.extent, this.background);

  final double extent;

  /// Parte de la comparación: si cambia el tema, el encabezado fijo se pinta de
  /// nuevo con el fondo nuevo (si no, se queda con el del tema anterior).
  final Color background;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate old) =>
      old.extent != extent || old.background != background;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // El hijo ocupa exactamente el alto declarado y centra el conmutador.
    return ColoredBox(
      color: background,
      child: SizedBox(
        height: extent,
        child: const Center(child: HomeTypeToggle()),
      ),
    );
  }
}
