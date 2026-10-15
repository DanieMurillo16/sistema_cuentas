import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';

/// Círculo con la inicial del nombre (el backend no guarda foto de perfil).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Usuario $name',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHigh,
          border: Border.all(color: AppColors.border),
        ),
        child: SizedBox.square(
          dimension: DesignTokens.avatarSize,
          child: Center(
            child: Text(
              displayInitial(name),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }
}
