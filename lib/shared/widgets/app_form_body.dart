import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// El cuerpo desplazable de un formulario de pantalla completa: ocupa lo que
/// deja el pie, se desplaza con el teclado abierto y estira sus campos. Debe ir
/// dentro de una `Column` (usa `Expanded` o `Flexible`).
class AppFormBody extends StatelessWidget {
  const AppFormBody({
    super.key,
    required this.formKey,
    required this.children,
    this.shrink = false,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  /// En una hoja inferior el cuerpo mide lo que midan sus campos (y se
  /// desplaza si no caben) en vez de ocupar todo el alto.
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
    return shrink ? Flexible(child: body) : Expanded(child: body);
  }
}
