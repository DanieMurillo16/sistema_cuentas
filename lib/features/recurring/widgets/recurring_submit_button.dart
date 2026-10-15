import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// «Crear pago recurrente»: con la petición en curso queda apagado y con progreso.
class RecurringSubmitButton extends StatelessWidget {
  const RecurringSubmitButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: DesignTokens.progressSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: 'Guardando',
                ),
              )
            : const Text('Crear pago recurrente'),
      ),
    );
  }
}
