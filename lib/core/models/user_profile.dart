/// La persona que inició sesión. Se usa en toda la app (cabecera, permisos,
/// usuarios), por eso vive en `core/models`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id_usuario'] as num).toInt(),
      fullName: json['nombre_completo'] as String? ?? '',
      username: json['usuario'] as String? ?? '',
      role: json['rol'] as String? ?? '',
    );
  }

  final int id;
  final String fullName;
  final String username;
  final String role;

  bool get isAdmin => role == 'ADMINISTRADOR';
}
