import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';

/// El único botón flotante de la app. Una sola acción principal por pantalla;
/// si hacen falta dos, la segunda va en el encabezado.
///
/// - [heroTag] es obligatorio y propio: sin etiqueta, dos rutas con flotante
///   chocan durante la transición.
/// - Con [label] es un botón extendido (una o dos palabras: el flotante tapa lo
///   que hay debajo). Sin [label] es un círculo solo con icono y [tooltip] dice
///   qué hace.
/// - [compactOnPhone] encoge el extendido en teléfono donde la lista de abajo
///   importa tanto como el botón.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.heroTag,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.compactOnPhone = false,
  }) : assert(label != null || tooltip != null, 'Pasa label o tooltip');

  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final String? tooltip;
  final bool compactOnPhone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = label;
    if (text == null) {
      return _Breathing(
        child: FloatingActionButton(
          heroTag: heroTag,
          tooltip: tooltip,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 4,
          onPressed: onPressed,
          child: Icon(icon, size: DesignTokens.iconLg),
        ),
      );
    }
    final narrow =
        compactOnPhone &&
        MediaQuery.sizeOf(context).width < DesignTokens.compactLayoutWidth;
    return _Breathing(
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        extendedPadding: narrow
            ? const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd)
            : null,
        onPressed: onPressed,
        icon: Icon(icon, size: narrow ? DesignTokens.iconSm : 24),
        label: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// El flotante late sin parar (crece un 16 %): se nota que es lo que se toca
/// para crear algo, sin tapar lo de al lado.
class _Breathing extends StatelessWidget {
  const _Breathing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppPulse(
    scale: 1.16,
    beat: const Duration(milliseconds: 1400),
    child: child,
  );
}
