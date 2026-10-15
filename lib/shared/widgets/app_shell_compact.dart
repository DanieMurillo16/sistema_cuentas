import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/widgets/floating_pill_nav.dart';

/// Distribución angosta del shell: contenido con la píldora flotante encima.
/// La píldora se oculta con el teclado abierto.
class AppShellCompact extends StatelessWidget {
  const AppShellCompact({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.content,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<AppDestination> onSelected;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // El contenido se aparta de la píldora: su botón flotante y sus
            // listas leen `MediaQuery.padding.bottom` para no quedar debajo.
            Positioned.fill(
              child: _ReserveBottom(reserve: !keyboardOpen, child: content),
            ),
            Positioned(
              left: DesignTokens.spaceMd,
              right: DesignTokens.spaceMd,
              bottom:
                  DesignTokens.floatingNavBottomGap +
                  MediaQuery.paddingOf(context).bottom,
              child: _PillSlot(
                visible: !keyboardOpen,
                child: FloatingPillNav(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelected: (i) => onSelected(destinations[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra u oculta la píldora con un deslizamiento y fundido, centrada y con
/// ancho máximo (en tablets no se estira de lado a lado).
class _PillSlot extends StatelessWidget {
  const _PillSlot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, DesignTokens.animationNormal);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: DesignTokens.floatingNavMaxWidth,
        ),
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: duration,
            curve: DesignTokens.curve,
            offset: visible ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: duration,
              opacity: visible ? 1 : 0,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Suma al padding inferior lo que ocupa la píldora (si se está viendo).
class _ReserveBottom extends StatelessWidget {
  const _ReserveBottom({required this.reserve, required this.child});

  final bool reserve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!reserve) return child; // con teclado la píldora no está
    final media = MediaQuery.of(context);
    return MediaQuery(
      // El botón flotante de Scaffold se apoya en `viewPadding`, las listas
      // en `padding`: se suma a los dos.
      data: media.copyWith(
        padding: media.padding.copyWith(
          bottom: media.padding.bottom + DesignTokens.floatingNavFootprint,
        ),
        viewPadding: media.viewPadding.copyWith(
          bottom: media.viewPadding.bottom + DesignTokens.floatingNavFootprint,
        ),
      ),
      child: child,
    );
  }
}
