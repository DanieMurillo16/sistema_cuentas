import 'package:flutter/material.dart';
import 'package:sistema_cuentas/shared/widgets/app_action_button.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

class DialogHeader extends StatelessWidget {
  const DialogHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.onClose,
    this.closeEnabled = true,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onClose;

  /// En `false` (por ejemplo mientras se guarda) el botón de cerrar queda
  /// apagado: sin esto, `onClose: null` caía al `pop()` por defecto.
  final bool closeEnabled;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.all(
        MediaQuery.viewInsetsOf(context).bottom > 0
            ? DesignTokens.spaceMd
            : DesignTokens.spaceLg,
      ),
      child: Row(
        children: [
          _HeaderIcon(icon: icon, color: accent),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDisplayText(title),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitle != null)
                  Text(
                    formatDisplayText(subtitle!),
                    // El encabezado no se desplaza: un subtítulo larguísimo
                    // no puede empujar el pie fuera del diálogo.
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          ...actions,
          AppActionButton(
            tooltip: 'Cerrar',
            onPressed: closeEnabled
                ? (onClose ?? () => Navigator.of(context).pop())
                : null,
            icon: Icons.close_rounded,
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceSm),
        child: Icon(icon, color: color),
      ),
    );
  }
}
