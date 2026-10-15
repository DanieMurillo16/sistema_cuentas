import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// «Iniciar sesión»: con la petición en curso queda apagado y muestra progreso
/// (así tampoco hay doble envío).
class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: DesignTokens.progressSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Iniciando sesión',
              ),
            )
          : const Text('Iniciar sesión'),
    );
  }
}
