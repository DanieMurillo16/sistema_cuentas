import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/providers/users_provider.dart';
import 'package:sistema_cuentas/features/users/widgets/user_active_switch.dart';
import 'package:sistema_cuentas/features/users/widgets/user_dialog.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/manage_list_scaffold.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

/// Ajustes → Usuarios (solo administrador): quién tiene acceso, dar de alta y
/// activar o desactivar.
/// pantalla → usersProvider → UsersRepository → usuarios/listar.php
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(hasPermissionProvider(Permissions.manageUsers));
    final myId = ref.watch(sessionUserIdProvider);
    // Un solo aviso por fallo (si cada fila escuchara, saldría uno por fila).
    ref.listen(setUserActiveProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasError) {
        AppToast.error(userErrorMessage(next.error));
      }
    });
    return ManageListScaffold<ManagedUser>(
      title: 'Usuarios',
      state: canManage
          ? ref.watch(usersProvider)
          : const AsyncData<List<ManagedUser>>([]),
      onRetry: () => ref.invalidate(usersProvider),
      emptyTitle: canManage ? 'Sin usuarios' : 'Sin acceso',
      emptyMessage: canManage
          ? 'Da de alta a las personas que usarán la app.'
          : 'Solo un administrador puede ver y crear usuarios.',
      createTooltip: 'Nuevo usuario',
      onCreate: canManage ? () => showUserDialog(context) : null,
      itemBuilder: (context, user) => ManageTile(
        key: ValueKey('user-${user.id}'),
        title: user.fullName,
        icon: user.isAdmin
            ? Icons.admin_panel_settings_outlined
            : Icons.person_outline_rounded,
        subtitle:
            '${user.username} · ${user.isAdmin ? 'Administrador' : 'Usuario'}',
        inactive: !user.active,
        trailing: UserActiveSwitch(user: user, isSelf: user.id == myId),
      ),
    );
  }
}
