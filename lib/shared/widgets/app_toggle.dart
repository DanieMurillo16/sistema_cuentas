import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option_tile.dart';

/// **El conmutador de la app.** Nada de `SegmentedButton` ni `ToggleButtons`:
/// se ven distintos entre pantallas.
///
/// Pastilla con el fondo hundido y la opción elegida encima, que se desliza al
/// cambiar. Dos o tres opciones; con más, usar `AppSearchDropdown`. Las
/// opciones salen de un `enum` o de un provider, nunca de una lista escrita a
/// mano.
///
/// Apagado ([enabled] false u [onSelected] null) se ve gris pero **no se
/// esconde**: que la opción exista y no aplique es información.
/// En pruebas se toca por el `InkWell` de la opción (no es un SegmentedButton).
class AppToggle<T> extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.compact = false,
    this.expanded = true,
  });

  final List<AppToggleOption<T>> options;
  final T selected;
  final ValueChanged<T>? onSelected;
  final bool enabled;

  /// Menos alto y menos letra, para una barra de filtros.
  final bool compact;

  /// Ocupa el ancho disponible y reparte las opciones por igual; en `false`
  /// mide lo que midan sus opciones, para ir dentro de una fila.
  final bool expanded;

  static const double _height = 46;
  static const double _compactHeight = 38;
  static const double _gap = 4;

  /// De -1 (izquierda) a 1 (derecha). Se alinea en vez de medir píxeles: un
  /// `LayoutBuilder` no soporta dimensiones intrínsecas dentro de
  /// `IntrinsicWidth`.
  static double alignmentFor(int index, int count) =>
      count <= 1 ? 0 : -1 + 2 * index / (count - 1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = enabled && onSelected != null;
    final index = options.indexWhere((o) => o.value == selected);

    final pill = Container(
      height: compact ? _compactHeight : _height,
      padding: const EdgeInsets.all(_gap),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: scheme.outline),
      ),
      child: Stack(
        children: [
          // La pastilla elegida va en Positioned.fill y la fila NO: un Stack se
          // mide por sus hijos sueltos y solo la fila sabe cuánto miden las
          // opciones (si no, IntrinsicWidth encogería el conmutador).
          if (index >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                duration: DesignTokens.animationFast,
                curve: Curves.easeOutCubic,
                alignment: Alignment(alignmentFor(index, options.length), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / options.length,
                  heightFactor: 1,
                  child: _Selection(
                    color: active
                        ? options[index].color ?? scheme.primary
                        : scheme.outline,
                    active: active,
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in options)
                Expanded(
                  child: AppToggleOptionTile<T>(
                    option: option,
                    chosen: option.value == selected,
                    enabled: active,
                    compact: compact,
                    onTap: active ? () => onSelected!(option.value) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return expanded ? pill : IntrinsicWidth(child: pill);
  }
}

class _Selection extends StatelessWidget {
  const _Selection({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: DesignTokens.animationFast,
    curve: Curves.easeOutCubic,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      boxShadow: active
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : const [],
    ),
  );
}
