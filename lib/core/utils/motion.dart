import 'package:flutter/widgets.dart';

/// Respeta "reducir movimiento" del sistema: sin animaciones, los cambios son
/// inmediatos. Toda animación de la app pasa su duración por aquí.
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
