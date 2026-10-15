import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

import '../helpers/auth_fixtures.dart';
import 'fake_auth_repository.dart';

/// Una sesión ya abierta (sin pasar por el login) con el rol y los permisos
/// que se pidan. Devuelve también el repositorio para leer `logoutCalls`.
({List<Override> overrides, FakeAuthRepository auth}) sessionOverrides({
  int id = 7,
  String fullName = 'Daniel Murillo',
  String role = 'USUARIO',
  Set<String> permissions = const {Permissions.registerMovements},
}) {
  final auth = FakeAuthRepository(
    storedToken: true,
    onFetchSession: () async => buildSession(
      id: id,
      fullName: fullName,
      role: role,
      permissions: permissions,
    ),
  );
  return (
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      // El id ya está resuelto desde el primer cuadro: los providers de datos
      // no se rehacen cuando termina de cargar la sesión (contar llamadas).
      sessionUserIdProvider.overrideWithValue(id),
    ],
    auth: auth,
  );
}

/// Sesión de administrador: gestiona usuarios y catálogos.
({List<Override> overrides, FakeAuthRepository auth}) adminSession({
  int id = 7,
  String fullName = 'Daniel Murillo',
}) => sessionOverrides(
  id: id,
  fullName: fullName,
  role: 'ADMINISTRADOR',
  permissions: const {
    Permissions.registerMovements,
    Permissions.manageCatalogs,
    Permissions.manageUsers,
  },
);
