import 'package:flutter/material.dart';

/// Cierra el teclado al tocar fuera de un campo, en cualquier pantalla.
///
/// Va montado una sola vez en la raíz de la app: las rutas, incluidas las de
/// `showDialog`, cuelgan del `Navigator`, que queda dentro de este envoltorio.
/// Con [HitTestBehavior.opaque] cuenta también el toque sobre fondos vacíos;
/// los campos y botones siguen respondiendo porque gana el reconocedor más
/// interno.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    // El foco primario y no el `FocusScope` de este contexto: en la raíz el
    // scope no es el de la pantalla que tiene el campo abierto.
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
}
