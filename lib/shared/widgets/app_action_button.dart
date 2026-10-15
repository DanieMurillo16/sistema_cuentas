import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: DesignTokens.actionIconSize),
      style: IconButton.styleFrom(
        foregroundColor: accent,
        backgroundColor: accent.withValues(alpha: 0.07),
        minimumSize: const Size.square(DesignTokens.actionSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),
    );
  }
}
