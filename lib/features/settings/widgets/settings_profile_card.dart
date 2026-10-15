import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/user_avatar.dart';

/// Quién tiene la sesión abierta: avatar, nombre, usuario y rol.
class SettingsProfileCard extends ConsumerWidget {
  const SettingsProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.value?.user));
    if (user == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Row(
          children: [
            UserAvatar(name: user.fullName),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDisplayText(user.fullName),
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    '${user.username} · ${user.isAdmin ? 'Administrador' : 'Usuario'}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
