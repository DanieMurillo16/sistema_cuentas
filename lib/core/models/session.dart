import 'package:sistema_cuentas/core/models/user_profile.dart';

/// Permisos como constantes (códigos `modulo.accion` del backend).
abstract final class Permissions {
  static const manageUsers = 'usuarios.gestionar';
  static const manageCatalogs = 'catalogos.gestionar';
  static const registerMovements = 'movimientos.registrar';
  static const cancelMovements = 'movimientos.anular';
  static const manageRecurring = 'pagos_recurrentes.gestionar';
}

/// Perfil y permisos de quien tiene la sesión abierta.
class Session {
  const Session({required this.user, required this.permissions});

  factory Session.fromJson(Map<String, dynamic> json) {
    final profile = json['perfil'];
    final permissions = json['permisos'];
    return Session(
      user: UserProfile.fromJson(Map<String, dynamic>.from(profile as Map)),
      permissions: {
        if (permissions is List) ...permissions.map((e) => e.toString()),
      },
    );
  }

  final UserProfile user;
  final Set<String> permissions;

  /// Esconder no es impedir: el backend también valida cada permiso.
  bool hasPermission(String code) => permissions.contains(code);
}
