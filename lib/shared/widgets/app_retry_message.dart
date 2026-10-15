import 'package:flutter/material.dart';

/// Mensaje corto con «Intentar nuevamente», para un bloque que no pudo cargar
/// (catálogos de un formulario, por ejemplo) sin tumbar toda la pantalla.
class AppRetryMessage extends StatelessWidget {
  const AppRetryMessage({super.key, required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(text, textAlign: TextAlign.center),
        TextButton(
          onPressed: onRetry,
          child: const Text('Intentar nuevamente'),
        ),
      ],
    );
  }
}
