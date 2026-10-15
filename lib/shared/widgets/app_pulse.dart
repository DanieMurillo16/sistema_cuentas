import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';

/// Late (crece y vuelve a su tamaño) para llamar la atención sobre algo que se
/// quiere que el usuario toque. Sin [beats] late sin parar (mientras se vea);
/// con [beats] late esas veces y se queda quieto. Con «reducir movimiento» no
/// se anima.
class AppPulse extends StatefulWidget {
  const AppPulse({
    super.key,
    required this.child,
    this.beats,
    this.scale = 1.035,
    this.beat = const Duration(milliseconds: 1100),
  });

  /// En pruebas se pone en `false`: un bucle sin fin no deja que
  /// `pumpAndSettle` termine, así que sin [beats] late una sola vez.
  static bool debugLoopForever = true;

  final Widget child;

  /// Cuántas veces late antes de quedarse quieto; `null` = sin parar.
  final int? beats;

  /// Tamaño máximo relativo al normal (1.035 = 3,5 % más grande).
  final double scale;

  /// Lo que dura crecer y volver a su tamaño.
  final Duration beat;

  @override
  State<AppPulse> createState() => _AppPulseState();
}

class _AppPulseState extends State<AppPulse>
    with SingleTickerProviderStateMixin {
  // Un tramo (crecer o volver) dura la mitad de un latido.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.beat ~/ 2,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: widget.scale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionDuration(context, widget.beat) == Duration.zero) return;
    final forever = widget.beats == null && AppPulse.debugLoopForever;
    if (forever) {
      _controller.repeat(reverse: true);
      return;
    }
    _controller
        .repeat(reverse: true, count: (widget.beats ?? 1) * 2)
        .whenComplete(() {
          // Termina exactamente en su tamaño normal.
          if (mounted) _controller.value = 0;
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
