import 'package:sistema_cuentas/core/utils/json_helpers.dart';

/// Una persona con acceso a la app, tal como la ve el administrador.
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.active,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
    id: asInt(json['id_usuario']),
    fullName: json['nombre_completo'] as String? ?? '',
    username: json['usuario'] as String? ?? '',
    role: json['rol'] as String? ?? '',
    active: json['activo'] != false,
  );

  final int id;
  final String fullName;
  final String username;
  final String role;
  final bool active;

  bool get isAdmin => role == 'ADMINISTRADOR';
}
