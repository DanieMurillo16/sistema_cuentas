import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Encabezado, cuerpo y pie en una columna. Si la hoja queda muy baja (pantalla
/// en horizontal, teclado abierto) el cuerpo toma un alto mínimo y todo se
/// desplaza en vez de desbordar.
class CatalogVisualLayout extends StatelessWidget {
  const CatalogVisualLayout({
    super.key,
    required this.header,
    required this.body,
    required this.actions,
  });

  final Widget header;
  final Widget body;
  final Widget actions;

  // Por debajo de este alto la columna no cabe con un cuerpo útil.
  static const _tightHeight = 180.0;
  static const _tightBodyHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight < _tightHeight;
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: DesignTokens.spaceMd),
            if (tight)
              SizedBox(height: _tightBodyHeight, child: body)
            else
              Expanded(child: body),
            const SizedBox(height: DesignTokens.spaceMd),
            actions,
          ],
        );
        return tight ? SingleChildScrollView(child: column) : column;
      },
    );
  }
}
