import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Tipo de aviso: define el color y el icono del toast.
enum ToastType {
  success(AppColors.success, Icons.check_circle_outline),
  error(AppColors.error, Icons.error_outline),
  warning(AppColors.warning, Icons.warning_amber_rounded),
  info(AppColors.info, Icons.info_outline);

  const ToastType(this.color, this.icon);

  final Color color;
  final IconData icon;
}

/// Cuerpo visual del toast: tarjeta de color con icono y texto blanco.
class AppToastCard extends StatelessWidget {
  const AppToastCard({super.key, required this.message, required this.type});

  final String message;
  final ToastType type;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DesignTokens.toastMaxWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: type.color,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
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
                vertical: DesignTokens.spaceSm + DesignTokens.spaceXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    color: AppColors.onPrimary,
                    size: DesignTokens.iconMd,
                  ),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Flexible(
                    child: Text(
                      message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
