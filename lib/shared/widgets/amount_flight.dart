import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Hace «volar» un monto desde [from] hasta el widget que tenga la llave
/// [target], y al llegar deja un destello en él. Se dibuja en el overlay raíz,
/// por encima de hojas y diálogos que se estén cerrando.
///
/// No hace nada si el destino no está en pantalla o si el sistema pide reducir
/// el movimiento: es un refuerzo visual, nunca algo de lo que dependa la tarea.
void playAmountFlight({
  required BuildContext context,
  required Offset from,
  required GlobalKey target,
  required String text,
  required Color color,
}) {
  if (MediaQuery.disableAnimationsOf(context)) return;
  final box = target.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.attached) return;
  final to = box.localToGlobal(box.size.center(Offset.zero));
  // Si la tarjeta quedó desplazada fuera de la pantalla (o bajo la barra de
  // arriba), el monto volaría a ninguna parte: mejor sin animación.
  final screen = MediaQuery.sizeOf(context);
  final top = MediaQuery.paddingOf(context).top;
  if (to.dy < top ||
      to.dy > screen.height ||
      to.dx < 0 ||
      to.dx > screen.width) {
    return;
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AmountFlight(
      from: from,
      to: to,
      text: text,
      color: color,
      onDone: () {
        entry.remove();
        entry.dispose();
      },
    ),
  );
  overlay.insert(entry);
}

class _AmountFlight extends StatefulWidget {
  const _AmountFlight({
    required this.from,
    required this.to,
    required this.text,
    required this.color,
    required this.onDone,
  });

  final Offset from;
  final Offset to;
  final String text;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_AmountFlight> createState() => _AmountFlightState();
}

class _AmountFlightState extends State<_AmountFlight>
    with SingleTickerProviderStateMixin {
  // 0 → 0.7: vuelo; 0.7 → 1: destello en el destino.
  static const _flightEnd = 0.7;
  static const _duration = DesignTokens.animationFlight;
  static const _arcHeight = 90.0;
  static const _ringSize = 120.0;

  late final _controller = AnimationController(vsync: this, duration: _duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _position(double t) {
    final control = Offset(
      (widget.from.dx + widget.to.dx) / 2,
      (widget.from.dy < widget.to.dy ? widget.from.dy : widget.to.dy) -
          _arcHeight,
    );
    final u = 1 - t;
    return widget.from * (u * u) + control * (2 * u * t) + widget.to * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          final flying = value < _flightEnd;
          final t = Curves.easeInOutCubic.transform(
            (value / _flightEnd).clamp(0.0, 1.0),
          );
          final ring = ((value - _flightEnd) / (1 - _flightEnd)).clamp(
            0.0,
            1.0,
          );
          final point = flying ? _position(t) : widget.to;
          return Stack(
            children: [
              if (!flying)
                Positioned(
                  left: widget.to.dx - _ringSize / 2,
                  top: widget.to.dy - _ringSize / 2,
                  child: Opacity(
                    opacity: 1 - ring,
                    child: Transform.scale(
                      scale: 0.3 + ring * 0.9,
                      child: _Ring(color: widget.color),
                    ),
                  ),
                ),
              if (flying)
                Positioned(
                  left: point.dx,
                  top: point.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Opacity(
                      opacity: t > 0.85 ? (1 - t) / 0.15 : 1,
                      child: Transform.scale(
                        scale: 1 - 0.35 * t,
                        child: _Chip(text: widget.text, color: widget.color),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.onBrand,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: const SizedBox.square(dimension: _AmountFlightState._ringSize),
    );
  }
}
