import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/shared/widgets/app_empty_view.dart';

/// Lo que se ve bajo el balance cuando no hay movimientos que mostrar: el mes
/// está vacío o no tiene del tipo que se eligió.
class HomeEmptyMessage extends StatelessWidget {
  const HomeEmptyMessage({super.key, required this.filter});

  /// `null` = se ve todo.
  final MovementType? filter;

  @override
  Widget build(BuildContext context) {
    final kind = filter?.plural.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceXl),
      child: AppEmptyView(
        icon: Icons.receipt_long_outlined,
        title: kind == null ? 'Sin movimientos este mes' : 'Sin $kind este mes',
        message: 'Toca «+» para registrar un ingreso o un gasto.',
      ),
    );
  }
}
