import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Una entrada del menú de Ajustes: icono, título, explicación corta y flecha.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Acción que borra algo: el icono va en rojo.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tone = destructive ? AppColors.expense : AppColors.accent;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  child: Icon(icon, color: tone),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
