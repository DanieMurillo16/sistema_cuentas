import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/confirm_action_dialog.dart';

/// «Cerrar sesión»: un botón sobrio al final de Ajustes, con confirmación.
/// Al cerrar, el router lleva solo al login.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmActionDialog(
        title: 'Cerrar sesión',
        message: 'Saldrás de tu cuenta en este dispositivo.',
        confirmLabel: 'Cerrar sesión',
        icon: Icons.logout_rounded,
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context, ref),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Cerrar sesión'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.expense,
        minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
        side: BorderSide(color: AppColors.expense.withValues(alpha: 0.5)),
      ),
    );
  }
}
