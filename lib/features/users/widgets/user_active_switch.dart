import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/providers/users_provider.dart';

/// Activar o desactivar a una persona (desactivar cierra sus sesiones). Nadie
/// cambia su propio estado: para uno mismo el interruptor va apagado.
class UserActiveSwitch extends ConsumerWidget {
  const UserActiveSwitch({super.key, required this.user, required this.isSelf});

  final ManagedUser user;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(setUserActiveProvider.select((s) => s.isLoading));
    return Semantics(
      label: '${user.fullName}: ${user.active ? 'activo' : 'inactivo'}',
      child: Tooltip(
        message: isSelf ? 'No puedes desactivarte a ti mismo' : 'Activo',
        child: Switch(
          value: user.active,
          onChanged: isSelf || busy
              ? null
              : (value) => ref
                    .read(setUserActiveProvider.notifier)
                    .setActive(user.id, active: value),
        ),
      ),
    );
  }
}
